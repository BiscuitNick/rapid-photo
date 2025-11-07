"""
CloudWatch metrics and structured logging utilities.
"""

import json
import logging
import time
from contextlib import contextmanager
from typing import Any, Dict, Optional

import boto3

from .config import AWS_REGION

logger = logging.getLogger(__name__)

# Initialize CloudWatch client
cloudwatch = boto3.client('cloudwatch', region_name=AWS_REGION)

# Metric namespace
NAMESPACE = 'RapidPhoto/Lambda'


class StructuredLogger:
    """Structured JSON logger for CloudWatch."""

    def __init__(self, logger_name: str = __name__):
        self.logger = logging.getLogger(logger_name)

    def log(self, level: str, message: str, **extra_fields):
        """
        Log structured JSON message.

        Args:
            level: Log level (info, warning, error, etc.)
            message: Log message
            **extra_fields: Additional fields to include in JSON
        """
        log_entry = {
            'message': message,
            'timestamp': time.time(),
            **extra_fields
        }

        log_func = getattr(self.logger, level.lower(), self.logger.info)
        log_func(json.dumps(log_entry))

    def info(self, message: str, **extra_fields):
        self.log('info', message, **extra_fields)

    def warning(self, message: str, **extra_fields):
        self.log('warning', message, **extra_fields)

    def error(self, message: str, **extra_fields):
        self.log('error', message, **extra_fields)


def put_metric(
    metric_name: str,
    value: float,
    unit: str = 'None',
    dimensions: Optional[Dict[str, str]] = None
):
    """
    Send custom metric to CloudWatch.

    Args:
        metric_name: Name of the metric
        value: Metric value
        unit: Metric unit (Count, Seconds, Bytes, etc.)
        dimensions: Optional metric dimensions
    """
    try:
        metric_data = {
            'MetricName': metric_name,
            'Value': value,
            'Unit': unit,
            'Timestamp': time.time()
        }

        if dimensions:
            metric_data['Dimensions'] = [
                {'Name': k, 'Value': v} for k, v in dimensions.items()
            ]

        cloudwatch.put_metric_data(
            Namespace=NAMESPACE,
            MetricData=[metric_data]
        )

        logger.debug(f"Sent metric: {metric_name}={value} {unit}")

    except Exception as e:
        # Don't fail processing if metrics fail
        logger.warning(f"Failed to send metric {metric_name}: {str(e)}")


@contextmanager
def timed_operation(operation_name: str, dimensions: Optional[Dict[str, str]] = None):
    """
    Context manager for timing operations and sending duration metrics.

    Args:
        operation_name: Name of the operation (used as metric name)
        dimensions: Optional metric dimensions

    Example:
        with timed_operation('image_processing'):
            process_image()
    """
    start_time = time.time()
    error_occurred = False

    try:
        yield
    except Exception:
        error_occurred = True
        raise
    finally:
        duration = time.time() - start_time

        # Send duration metric
        put_metric(
            f"{operation_name}.duration",
            duration,
            unit='Seconds',
            dimensions=dimensions
        )

        # Send success/failure counter
        put_metric(
            f"{operation_name}.count",
            1,
            unit='Count',
            dimensions={
                **(dimensions or {}),
                'status': 'error' if error_occurred else 'success'
            }
        )

        logger.info(
            f"Operation '{operation_name}' completed in {duration:.2f}s "
            f"(status: {'error' if error_occurred else 'success'})"
        )


def increment_counter(
    counter_name: str,
    value: int = 1,
    dimensions: Optional[Dict[str, str]] = None
):
    """
    Increment a counter metric.

    Args:
        counter_name: Name of the counter
        value: Value to increment by (default: 1)
        dimensions: Optional metric dimensions
    """
    put_metric(counter_name, value, unit='Count', dimensions=dimensions)
