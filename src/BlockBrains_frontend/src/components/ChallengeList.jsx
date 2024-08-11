import React from 'react';

function ChallengeList({ challenges, onChallengeClick }) {
  return (
    <div className="challenge-list">
      {challenges.map((challenge) => (
        <div key={challenge.id} className="challenge-card" onClick={() => onChallengeClick(challenge)}>
          <h2>{challenge.title}</h2>
          <p className="description">{challenge.description}</p>
          <span className="status">Status: {challenge.status === 'Open' ? 'Open' : 'Closed'}</span>
          <span className="created-at">Created: {new Date(Number(challenge.createdAt) / 1000000).toLocaleString()}</span>
        </div>
      ))}
    </div>
  );
}

export default ChallengeList;