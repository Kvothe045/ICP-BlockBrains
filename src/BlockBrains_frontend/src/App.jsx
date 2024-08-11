import React, { useState, useEffect } from 'react';
import { BlockBrains_backend } from 'declarations/BlockBrains_backend';
import Header from './components/Header';
import ChallengeList from './components/ChallengeList';
import ChallengeDetail from './components/ChallengeDetail';
import CreateChallengeForm from './components/CreateChallengeForm';
import StatusMessage from './components/StatusMessage';

function App() {
  const [challenges, setChallenges] = useState([]);
  const [selectedChallenge, setSelectedChallenge] = useState(null);
  const [showCreateForm, setShowCreateForm] = useState(false);
  const [statusMessage, setStatusMessage] = useState(null);

  useEffect(() => {
    fetchChallenges();
  }, []);

  async function fetchChallenges() {
    try {
      setStatusMessage({ message: "Fetching challenges...", type: "info" });
      const result = await BlockBrains_backend.getAllChallenges();
      console.log("Fetched challenges:", result);
      setChallenges(result);
      setStatusMessage(null);
    } catch (error) {
      console.error("Failed to fetch challenges:", error);
      setStatusMessage({ message: "Failed to fetch challenges. Please try again.", type: "error" });
    }
  }

  function handleChallengeClick(challenge) {
    setSelectedChallenge(challenge);
  }

  function handleBackToList() {
    setSelectedChallenge(null);
  }

  function handleCreateChallenge() {
    setShowCreateForm(true);
  }

  async function handleChallengeCreated(newChallenge) {
    setShowCreateForm(false);
    setStatusMessage({ message: "Challenge created successfully!", type: "success" });
    console.log("New challenge created:", newChallenge);
    await fetchChallenges();
  }

  return (
    <div className="app">
      <Header onCreateChallenge={handleCreateChallenge} />
      {statusMessage && <StatusMessage message={statusMessage.message} type={statusMessage.type} />}
      {showCreateForm ? (
        <CreateChallengeForm 
          onClose={() => setShowCreateForm(false)} 
          onChallengeCreated={handleChallengeCreated}
          setStatusMessage={setStatusMessage}
        />
      ) : selectedChallenge ? (
        <ChallengeDetail 
          challenge={selectedChallenge} 
          onBack={handleBackToList}
          setStatusMessage={setStatusMessage}
        />
      ) : (
        <>
          <ChallengeList challenges={challenges} onChallengeClick={handleChallengeClick} />
          {challenges.length === 0 && !statusMessage && 
            <StatusMessage message="No challenges found. Create a new one!" type="info" />
          }
        </>
      )}
    </div>
  );
}

export default App;