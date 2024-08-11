import Array "mo:base/Array";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Float "mo:base/Float";
import Order "mo:base/Order";
import Hash "mo:base/Hash";

actor ExpertFeedbackPlatform {

    // Types
    type ExpertId = Principal;
    type OrganizationId = Principal;
    type ChallengeId = Nat;
    type FeedbackId = Nat;

    type Expert = {
        id: ExpertId;
        credentials: Text;
        rating: Float;
        totalRatings: Nat;
        tokenBalance: Nat;
    };

    type Organization = {
        id: OrganizationId;
        name: Text;
        tokenBalance: Nat;
    };

    type Challenge = {
        id: ChallengeId;
        organizationId: OrganizationId;
        title: Text;
        description: Text;
        isPublic: Bool;
        createdAt: Time.Time;
        status: ChallengeStatus;
    };

    type ChallengeStatus = {
        #Open;
        #Closed;
    };

    type Feedback = {
        id: FeedbackId;
        challengeId: ChallengeId;
        expertId: ExpertId;
        content: Text;
        rating: ?Float;
        createdAt: Time.Time;
    };

    // Errors
    type Error = {
        #NotFound;
        #AlreadyExists;
        #NotAuthorized;
        #InsufficientBalance;
        #InvalidInput;
    };

    // State
    private stable var nextChallengeId: Nat = 0;
    private stable var nextFeedbackId: Nat = 0;
    private stable var expertsEntries: [(ExpertId, Expert)] = [];
    private stable var organizationsEntries: [(OrganizationId, Organization)] = [];
    private stable var challengesEntries: [(ChallengeId, Challenge)] = [];
    private stable var feedbacksEntries: [(FeedbackId, Feedback)] = [];

    private var experts: HashMap.HashMap<ExpertId, Expert> = HashMap.fromIter(expertsEntries.vals(), 10, Principal.equal, Principal.hash);
    private var organizations: HashMap.HashMap<OrganizationId, Organization> = HashMap.fromIter(organizationsEntries.vals(), 10, Principal.equal, Principal.hash);
    private var challenges: HashMap.HashMap<ChallengeId, Challenge> = HashMap.fromIter(challengesEntries.vals(), 10, Nat.equal, Hash.hash);
    private var feedbacks: HashMap.HashMap<FeedbackId, Feedback> = HashMap.fromIter(feedbacksEntries.vals(), 10, Nat.equal, Hash.hash);

    // Upgrade hooks
    system func preupgrade() {
        expertsEntries := Iter.toArray(experts.entries());
        organizationsEntries := Iter.toArray(organizations.entries());
        challengesEntries := Iter.toArray(challenges.entries());
        feedbacksEntries := Iter.toArray(feedbacks.entries());
    };

    system func postupgrade() {
        experts := HashMap.fromIter(expertsEntries.vals(), 10, Principal.equal, Principal.hash);
        organizations := HashMap.fromIter(organizationsEntries.vals(), 10, Principal.equal, Principal.hash);
        challenges := HashMap.fromIter(challengesEntries.vals(), 10, Nat.equal, Hash.hash);
        feedbacks := HashMap.fromIter(feedbacksEntries.vals(), 10, Nat.equal, Hash.hash);
    };

    // Expert Management
    public shared(msg) func registerExpert(credentials: Text) : async Result.Result<(), Error> {
        let expertId = msg.caller;
        switch (experts.get(expertId)) {
            case (?_) { #err(#AlreadyExists) };
            case null {
                let newExpert: Expert = {
                    id = expertId;
                    credentials = credentials;
                    rating = 0;
                    totalRatings = 0;
                    tokenBalance = 0;
                };
                experts.put(expertId, newExpert);
                #ok(())
            };
        }
    };

    public query func getExpert(id: ExpertId) : async Result.Result<Expert, Error> {
        switch (experts.get(id)) {
            case (?expert) { #ok(expert) };
            case null { #err(#NotFound) };
        }
    };

    // Organization Management
    public shared(msg) func registerOrganization(name: Text) : async Result.Result<(), Error> {
        let orgId = msg.caller;
        switch (organizations.get(orgId)) {
            case (?_) { #err(#AlreadyExists) };
            case null {
                let newOrg: Organization = {
                    id = orgId;
                    name = name;
                    tokenBalance = 1000; // Initial token balance
                };
                organizations.put(orgId, newOrg);
                #ok(())
            };
        }
    };

    public query func getOrganization(id: OrganizationId) : async Result.Result<Organization, Error> {
        switch (organizations.get(id)) {
            case (?org) { #ok(org) };
            case null { #err(#NotFound) };
        }
    };

    // Challenge Management
    public shared(msg) func createChallenge(title: Text, description: Text, isPublic: Bool) : async Result.Result<ChallengeId, Error> {
        let orgId = msg.caller;
        switch (organizations.get(orgId)) {
            case null { #err(#NotAuthorized) };
            case (?_) {
                let challengeId = nextChallengeId;
                nextChallengeId += 1;

                let newChallenge: Challenge = {
                    id = challengeId;
                    organizationId = orgId;
                    title = title;
                    description = description;
                    isPublic = isPublic;
                    createdAt = Time.now();
                    status = #Open;
                };

                challenges.put(challengeId, newChallenge);
                #ok(challengeId)
            };
        }
    };

    public query func getChallenge(id: ChallengeId) : async Result.Result<Challenge, Error> {
        switch (challenges.get(id)) {
            case (?challenge) { #ok(challenge) };
            case null { #err(#NotFound) };
        }
    };

    public shared(msg) func closeChallenge(id: ChallengeId) : async Result.Result<(), Error> {
        let orgId = msg.caller;
        switch (challenges.get(id)) {
            case null { #err(#NotFound) };
            case (?challenge) {
                if (challenge.organizationId != orgId) {
                    #err(#NotAuthorized)
                } else {
                    let updatedChallenge: Challenge = {
                        challenge with status = #Closed;
                    };
                    challenges.put(id, updatedChallenge);
                    #ok(())
                }
            };
        }
    };

    // Feedback Management
    public shared(msg) func submitFeedback(challengeId: ChallengeId, content: Text) : async Result.Result<FeedbackId, Error> {
        let expertId = msg.caller;
        switch (experts.get(expertId), challenges.get(challengeId)) {
            case (?_, ?challenge) {
                if (challenge.status == #Closed) {
                    #err(#NotAuthorized)
                } else {
                    let feedbackId = nextFeedbackId;
                    nextFeedbackId += 1;

                    let newFeedback: Feedback = {
                        id = feedbackId;
                        challengeId = challengeId;
                        expertId = expertId;
                        content = content;
                        rating = null;
                        createdAt = Time.now();
                    };

                    feedbacks.put(feedbackId, newFeedback);
                    #ok(feedbackId)
                }
            };
            case (_, _) { #err(#NotFound) };
        }
    };

    public query func getFeedback(id: FeedbackId) : async Result.Result<Feedback, Error> {
        switch (feedbacks.get(id)) {
            case (?feedback) { #ok(feedback) };
            case null { #err(#NotFound) };
        }
    };

    // Rating System
    public shared(msg) func rateFeedback(feedbackId: FeedbackId, rating: Float) : async Result.Result<(), Error> {
        let orgId = msg.caller;
        switch (feedbacks.get(feedbackId), organizations.get(orgId)) {
            case (?feedback, ?_) {
                if (rating < 0 or rating > 5) {
                    return #err(#InvalidInput);
                };
                let updatedFeedback: Feedback = {
                    feedback with rating = ?rating;
                };
                feedbacks.put(feedbackId, updatedFeedback);

                // Update expert rating
                switch (experts.get(feedback.expertId)) {
                    case (?expert) {
                        let newTotalRatings = expert.totalRatings + 1;
                        let newRating = (expert.rating * Float.fromInt(expert.totalRatings) + rating) / Float.fromInt(newTotalRatings);
                        let updatedExpert: Expert = {
                            expert with
                            rating = newRating;
                            totalRatings = newTotalRatings;
                        };
                        experts.put(expert.id, updatedExpert);
                    };
                    case null { /* This shouldn't happen, but we'll ignore it */ };
                };
                #ok(())
            };
            case (_, _) { #err(#NotFound) };
        }
    };

    // Token System
    public shared(msg) func awardTokens(expertId: ExpertId, amount: Nat) : async Result.Result<(), Error> {
        let orgId = msg.caller;
        switch (organizations.get(orgId), experts.get(expertId)) {
            case (?org, ?expert) {
                if (org.tokenBalance < amount) {
                    #err(#InsufficientBalance)
                } else {
                    let updatedOrg: Organization = {
                        org with tokenBalance = org.tokenBalance - amount;
                    };
                    let updatedExpert: Expert = {
                        expert with tokenBalance = expert.tokenBalance + amount;
                    };
                    organizations.put(orgId, updatedOrg);
                    experts.put(expertId, updatedExpert);
                    #ok(())
                }
            };
            case (_, _) { #err(#NotFound) };
        }
    };

    // Query functions for frontend
    public query func getAllChallenges() : async [Challenge] {
        Iter.toArray(challenges.vals())
    };

    public query func getChallengesByOrganization(orgId: OrganizationId) : async [Challenge] {
        Iter.toArray(Iter.filter(challenges.vals(), func(challenge: Challenge) : Bool {
            challenge.organizationId == orgId
        }))
    };

    public query func getFeedbacksByChallenge(challengeId: ChallengeId) : async [Feedback] {
        Iter.toArray(Iter.filter(feedbacks.vals(), func(feedback: Feedback) : Bool {
            feedback.challengeId == challengeId
        }))
    };

    // New query functions
    public query func getTopExperts(limit: Nat) : async [Expert] {
        let sortedExperts = Array.sort(Iter.toArray(experts.vals()), func(a: Expert, b: Expert) : Order.Order {
            if (a.rating > b.rating) { #less } else if (a.rating < b.rating) { #greater } else { #equal }
        });
        Array.subArray(sortedExperts, 0, Nat.min(limit, sortedExperts.size()))
    };

    public query func getOpenChallenges() : async [Challenge] {
        Iter.toArray(Iter.filter(challenges.vals(), func(challenge: Challenge) : Bool {
            challenge.status == #Open
        }))
    };
}
