import React, { useState } from 'react';
import { BlockBrains_backend } from 'declarations/BlockBrains_backend';

function CreateChallengeForm({ onClose, onChallengeCreated, setStatusMessage }) {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [isPublic, setIsPublic] = useState(true);

  async function handleSubmit(e) {
    e.preventDefault();
    try {
      setStatusMessage({ message: "Creating challenge...", type: "info" });
      const result = await BlockBrains_backend.createChallenge(title, description, isPublic);
      console.log("Challenge creation result:", result);
      onChallengeCreated(result);
    } catch (error) {
      console.error("Failed to create challenge:", error);
      setStatusMessage({ message: "Failed to create challenge. Please try again.", type: "error" });
    }
  }

  return (
    <div className="create-challenge-form">
      <h2>Create New Challenge</h2>
      <form onSubmit={handleSubmit}>
        <input
          type="text"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder="Challenge Title"
          required
        />
        <textarea
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          placeholder="Challenge Description"
          required
        />
        <label>
          <input
            type="checkbox"
            checked={isPublic}
            onChange={(e) => setIsPublic(e.target.checked)}
          />
          Make this challenge public
        </label>
        <button type="submit">Create Challenge</button>
        <button type="button" onClick={onClose}>Cancel</button>
      </form>
    </div>
  );
}

export default CreateChallengeForm;