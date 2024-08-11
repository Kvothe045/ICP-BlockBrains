import React from 'react';

function StatusMessage({ message, type = 'info' }) {
  return (
    <div className={`status-message ${type}`}>
      {message}
    </div>
  );
}

export default StatusMessage;