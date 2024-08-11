import React, { useState, useEffect } from 'react';
import { BlockBrains_backend } from 'declarations/BlockBrains_backend';

function ChallengeDetail({ challenge, onBack }) {
  const [feedbacks, setFeedbacks] = useState([]);
  const [newFeedback, setNewFeedback] = useState('');

  useEffect(() => {
    fetchFeedbacks();
  }, [challenge]);

  async function fetchFeedbacks() {
    try {
      const result = await BlockBrains_backend.getFeedbacksByChallenge(challenge.id);
      setFeedbacks(result);
    } catch (error) {
      console.error("Failed to fetch feedbacks:", error);
    }
  }

  async function handleSubmitFeedback(e) {
    e.preventDefault();
    try {
      await blockbrains_backend.submitFeedback(challenge.id, newFeedback);
      setNewFeedback('');
      fetchFeedbacks();
    } catch (error) {
      console.error("Failed to submit feedback:", error);
    }
  }

  async function handleRateFeedback(feedbackId, rating) {
    try {
      await blockbrains_backend.rateFeedback(feedbackId, rating);
      fetchFeedbacks();
    } catch (error) {
      console.error("Failed to rate feedback:", error);
    }
  }

  return (
    <div className="challenge-detail">
      <button onClick={onBack}>Back to List</button>
      <h2>{challenge.title}</h2>
      <p>{challenge.description}</p>
      <span>Status: {challenge.status === 'Open' ? 'Open' : 'Closed'}</span>
      <h3>Feedbacks:</h3>
      {feedbacks.map((feedback) => (
        <div key={feedback.id} className="feedback-item">
          <p>{feedback.content}</p>
          <span>By: {feedback.expertId.toText()}</span>
          {feedback.rating ? (
            <span>Rating: {feedback.rating}</span>
          ) : (
            <div>
              Rate:
              {[1, 2, 3, 4, 5].map((star) => (
                <button key={star} onClick={() => handleRateFeedback(feedback.id, star)}>
                  {star}
                </button>
              ))}
            </div>
          )}
        </div>
      ))}
      {challenge.status === 'Open' && (
        <form onSubmit={handleSubmitFeedback}>
          <textarea
            value={newFeedback}
            onChange={(e) => setNewFeedback(e.target.value)}
            placeholder="Write your feedback..."
            required
          />
          <button type="submit">Submit Feedback</button>
        </form>
      )}
    </div>
  );
}

export default ChallengeDetail;