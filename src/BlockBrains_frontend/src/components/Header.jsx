import React from 'react';

function Header({ onCreateChallenge }) {
  return (
    <header className="header">
      <h1>BlockBrains</h1>
      <button onClick={onCreateChallenge}>Create New Challenge</button>
    </header>
  );
}

export default Header;