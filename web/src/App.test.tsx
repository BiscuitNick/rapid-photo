import { describe, it, expect } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import App from './App';

describe('App', () => {
  it('renders the app title', () => {
    render(<App />);
    expect(screen.getByText('RapidPhoto Upload')).toBeInTheDocument();
  });

  it('increments counter when button is clicked', () => {
    render(<App />);
    const button = screen.getByText(/Count: 0/);
    fireEvent.click(button);
    expect(screen.getByText('Count: 1')).toBeInTheDocument();
  });

  it('resets counter when reset button is clicked', () => {
    render(<App />);
    const countButton = screen.getByText(/Count: 0/);
    const resetButton = screen.getByText('Reset');

    fireEvent.click(countButton);
    fireEvent.click(countButton);
    expect(screen.getByText('Count: 2')).toBeInTheDocument();

    fireEvent.click(resetButton);
    expect(screen.getByText('Count: 0')).toBeInTheDocument();
  });
});
