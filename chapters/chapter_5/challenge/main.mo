import Result "mo:base/Result";
import HashMap "mo:base/HashMap";
import TrieMap "mo:base/TrieMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Buffer "mo:base/Buffer";
import Nat64 "mo:base/Nat64";
import Iter "mo:base/Iter";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Option "mo:base/Option";
import Time "mo:base/Time";
import Array "mo:base/Array";
import Types "types";
actor {
    // For this level we need to make use of the code implemented in the previous projects.
    // The voting system will make use of previous data structures and functions.

    /////////////////
    //   TYPES    //
    ///////////////
    type Member = Types.Member;
    type Result<Ok, Err> = Types.Result<Ok, Err>;
    type HashMap<K, V> = Types.HashMap<K, V>;
    type Proposal = Types.Proposal;
    type ProposalContent = Types.ProposalContent;
    type ProposalId = Types.ProposalId;
    type Vote = Types.Vote;
    type DAOStats = Types.DAOStats;
    type HttpRequest = Types.HttpRequest;
    type HttpResponse = Types.HttpResponse;

    /////////////////
    // PROJECT #1 //
    ///////////////
    let goals = Buffer.Buffer<Text>(0);
    let name = "Motoko Bootcamp";
    var manifesto = "Empower the next generation of builders and make the DAO-revolution a reality";

    public shared query func getName() : async Text {
        return name;
    };

    public shared query func getManifesto() : async Text {
        return manifesto;
    };

    public func setManifesto(newManifesto : Text) : async () {
        manifesto := newManifesto;
        return;
    };

    public func addGoal(newGoal : Text) : async () {
        goals.add(newGoal);
        return;
    };

    public shared query func getGoals() : async [Text] {
        Buffer.toArray(goals);
    };

    /////////////////
    // PROJECT #2 //
    ///////////////
    let members = HashMap.HashMap<Principal, Member>(0, Principal.equal, Principal.hash);

    public shared ({ caller }) func addMember(member : Member) : async Result<(), Text> {
        switch (members.get(caller)) {
            case (null) {
                members.put(caller, member);
                return #ok();
            };
            case (?member) {
                return #err("Member already exists");
            };
        };
    };

    public shared ({ caller }) func updateMember(member : Member) : async Result<(), Text> {
        switch (members.get(caller)) {
            case (null) {
                return #err("Member does not exist");
            };
            case (?member) {
                members.put(caller, member);
                return #ok();
            };
        };
    };

    public shared ({ caller }) func removeMember() : async Result<(), Text> {
        switch (members.get(caller)) {
            case (null) {
                return #err("Member does not exist");
            };
            case (?member) {
                members.delete(caller);
                return #ok();
            };
        };
    };

    public query func getMember(p : Principal) : async Result<Member, Text> {
        switch (members.get(p)) {
            case (null) {
                return #err("Member does not exist");
            };
            case (?member) {
                return #ok(member);
            };
        };
    };

    public query func getAllMembers() : async [Member] {
        return Iter.toArray(members.vals());
    };

    public query func numberOfMembers() : async Nat {
        return members.size();
    };

    /////////////////
    // PROJECT #3 //
    ///////////////
    let ledger = HashMap.HashMap<Principal, Nat>(0, Principal.equal, Principal.hash);

    public query func tokenName() : async Text {
        return "Motoko Bootcamp Token";
    };

    public query func tokenSymbol() : async Text {
        return "MBT";
    };

    public func mint(owner : Principal, amount : Nat) : async Result<(), Text> {
        let balance = Option.get(ledger.get(owner), 0);
        ledger.put(owner, balance + amount);
        return #ok();
    };

    public func burn(owner : Principal, amount : Nat) : async Result<(), Text> {
        let balance = Option.get(ledger.get(owner), 0);
        if (balance < amount) {
            return #err("Insufficient balance to burn");
        };
        ledger.put(owner, balance - amount);
        return #ok();
    };

    func _burn(owner : Principal, amount : Nat) : () {
        let balance = Option.get(ledger.get(owner), 0);
        ledger.put(owner, balance - amount);
        return;
    };

    public shared ({ caller }) func transfer(from : Principal, to : Principal, amount : Nat) : async Result<(), Text> {
        let balanceFrom = Option.get(ledger.get(from), 0);
        let balanceTo = Option.get(ledger.get(to), 0);
        if (balanceFrom < amount) {
            return #err("Insufficient balance to transfer");
        };
        ledger.put(from, balanceFrom - amount);
        ledger.put(to, balanceTo + amount);
        return #ok();
    };

    public query func balanceOf(owner : Principal) : async Nat {
        return (Option.get(ledger.get(owner), 0));
    };

    public query func totalSupply() : async Nat {
        var total = 0;
        for (balance in ledger.vals()) {
            total += balance;
        };
        return total;
    };
    /////////////////
    // PROJECT #4 //
    ///////////////
    var nextProposalId : Nat64 = 0;
    let proposals = HashMap.HashMap<ProposalId, Proposal>(0, Nat64.equal, Nat64.toNat32);

    public shared ({ caller }) func createProposal(content : ProposalContent) : async Result<ProposalId, Text> {
        switch (members.get(caller)) {
            case (null) {
                return #err("The caller is not a member - cannot create a proposal");
            };
            case (?member) {
                let balance = Option.get(ledger.get(caller), 0);
                if (balance < 1) {
                    return #err("The caller does not have enough tokens to create a proposal");
                };
                // Create the proposal and burn the tokens
                let proposal : Proposal = {
                    id = nextProposalId;
                    content;
                    creator = caller;
                    created = Time.now();
                    executed = null;
                    votes = [];
                    voteScore = 0;
                    status = #Open;
                };
                proposals.put(nextProposalId, proposal);
                nextProposalId += 1;
                _burn(caller, 1);
                return #ok(nextProposalId - 1);
            };
        };
    };

    public query func getProposal(proposalId : ProposalId) : async ?Proposal {
        return proposals.get(proposalId);
    };

    public shared ({ caller }) func voteProposal(proposalId : ProposalId, vote : Vote) : async Result<(), Text> {
        // Check if the caller is a member of the DAO
        switch (members.get(caller)) {
            case (null) {
                return #err("The caller is not a member - canno vote one proposal");
            };
            case (?member) {
                // Check if the proposal exists
                switch (proposals.get(proposalId)) {
                    case (null) {
                        return #err("The proposal does not exist");
                    };
                    case (?proposal) {
                        // Check if the proposal is open for voting
                        if (proposal.status != #Open) {
                            return #err("The proposal is not open for voting");
                        };
                        // Check if the caller has already voted
                        if (_hasVoted(proposal, caller)) {
                            return #err("The caller has already voted on this proposal");
                        };
                        let balance = Option.get(ledger.get(caller), 0);
                        let multiplierVote = switch (vote.yesOrNo) {
                            case (true) { 1 };
                            case (false) { -1 };
                        };
                        let newVoteScore = proposal.voteScore + balance * multiplierVote;
                        var newExecuted : ?Time.Time = null;
                        let newVotes = Buffer.fromArray<Vote>(proposal.votes);
                        let newStatus = if (newVoteScore >= 100) {
                            #Accepted;
                        } else if (newVoteScore <= -100) {
                            #Rejected;
                        } else {
                            #Open;
                        };
                        switch (newStatus) {
                            case (#Accepted) {
                                _executeProposal(proposal.content);
                                newExecuted := ?Time.now();
                            };
                            case (_) {};
                        };
                        let newProposal : Proposal = {
                            id = proposal.id;
                            content = proposal.content;
                            creator = proposal.creator;
                            created = proposal.created;
                            executed = newExecuted;
                            votes = Buffer.toArray(newVotes);
                            voteScore = newVoteScore;
                            status = newStatus;
                        };
                        proposals.put(proposal.id, newProposal);
                        return #ok();
                    };
                };
            };
        };
    };

    func _hasVoted(proposal : Proposal, member : Principal) : Bool {
        return Array.find<Vote>(
            proposal.votes,
            func(vote : Vote) {
                return vote.member == member;
            },
        ) != null;
    };

    func _executeProposal(content : ProposalContent) : () {
        switch (content) {
            case (#ChangeManifesto(newManifesto)) {
                manifesto := newManifesto;
            };
            case (#AddGoal(newGoal)) {
                goals.add(newGoal);
            };
        };
        return;
    };

    public query func getAllProposals() : async [Proposal] {
        return Iter.toArray(proposals.vals());
    };

    /////////////////
    // PROJECT #5 //
    ///////////////
    let logo : Text = "<?xml version='1.0' encoding='UTF-8'?>
<!DOCTYPE svg PUBLIC '-//W3C//DTD SVG 1.1//EN' 'http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd'>
<svg xmlns='http://www.w3.org/2000/svg' version='1.1' width='434px' height='342px' style='shape-rendering:geometricPrecision; text-rendering:geometricPrecision; image-rendering:optimizeQuality; fill-rule:evenodd; clip-rule:evenodd' xmlns:xlink='http://www.w3.org/1999/xlink'>
<g><path style='opacity:1' fill='#fefefe' d='M 33.5,0.5 C 154.5,0.5 275.5,0.5 396.5,0.5C 396.5,64.5 396.5,128.5 396.5,192.5C 400.5,192.5 404.5,192.5 408.5,192.5C 408.5,241.833 408.5,291.167 408.5,340.5C 283.5,340.5 158.5,340.5 33.5,340.5C 33.5,227.167 33.5,113.833 33.5,0.5 Z'/></g>
<g><path style='opacity:1' fill='#46628d' d='M 193.5,76.5 C 192.833,76.5 192.167,76.5 191.5,76.5C 177.287,69.7528 171.12,58.4194 173,42.5C 178.624,25.1074 190.124,18.9407 207.5,24C 221.641,33.089 225.807,45.589 220,61.5C 214.407,72.2665 205.573,77.2665 193.5,76.5 Z'/></g>
<g><path style='opacity:1' fill='#e8425e' d='M 193.5,25.5 C 211.469,26.6493 219.636,36.316 218,54.5C 214.372,67.4645 205.872,73.2978 192.5,72C 180.42,66.344 175.253,56.844 177,43.5C 179.619,34.7195 185.119,28.7195 193.5,25.5 Z'/></g>
<g><path style='opacity:1' fill='#436590' d='M 246.5,102.5 C 247.113,98.0712 245.78,94.4046 242.5,91.5C 241.499,75.9781 248.166,65.4781 262.5,60C 281.246,58.9088 291.58,67.7422 293.5,86.5C 291.901,106.268 281.234,115.435 261.5,114C 255.15,111.803 250.15,107.97 246.5,102.5 Z'/></g>
<g><path style='opacity:1' fill='#cabfd8' d='M 263.5,63.5 C 282.085,64.2538 290.585,73.9204 289,92.5C 283.22,108.977 272.387,113.811 256.5,107C 243.586,94.2926 243.253,81.2926 255.5,68C 258.099,66.205 260.766,64.705 263.5,63.5 Z'/></g>
<g><path style='opacity:1' fill='#e8455f' d='M 242.5,91.5 C 245.78,94.4046 247.113,98.0712 246.5,102.5C 244.915,112.67 240.415,121.337 233,128.5C 232.218,123.869 231.051,119.369 229.5,115C 232.939,110.79 235.606,106.123 237.5,101C 236.892,100.13 236.059,99.6301 235,99.5C 232.078,100.755 229.411,102.422 227,104.5C 226.587,101.768 225.92,99.1013 225,96.5C 224.211,113.19 224.544,129.857 226,146.5C 228.768,162.121 237.935,169.121 253.5,167.5C 253.5,173.167 253.5,178.833 253.5,184.5C 247.833,184.5 242.167,184.5 236.5,184.5C 236.666,179.821 236.499,175.155 236,170.5C 232.368,167.87 229.035,164.87 226,161.5C 222.088,164.541 217.921,167.208 213.5,169.5C 212.345,172.446 212.179,175.446 213,178.5C 216.016,181.349 218.85,184.349 221.5,187.5C 218.016,191.485 214.349,195.318 210.5,199C 209.423,199.47 208.423,199.303 207.5,198.5C 205.5,196.167 203.5,193.833 201.5,191.5C 201.027,190.094 200.027,189.427 198.5,189.5C 197.588,188.262 197.421,186.928 198,185.5C 200.963,183.539 203.629,181.206 206,178.5C 206.495,176.527 206.662,174.527 206.5,172.5C 190.999,175.618 182.999,169.452 182.5,154C 182.473,148.284 183.473,142.784 185.5,137.5C 189.754,130.001 194.754,123.001 200.5,116.5C 202.125,122.415 202.625,128.415 202,134.5C 197.185,142.187 196.185,150.187 199,158.5C 200.645,160.662 202.812,161.995 205.5,162.5C 206.308,164.423 206.808,166.423 207,168.5C 208.039,148.769 207.372,129.102 205,109.5C 203.688,99.8546 198.188,94.6879 188.5,94C 187.484,93.4806 186.818,92.6473 186.5,91.5C 187.601,86.1973 189.268,81.1973 191.5,76.5C 192.167,76.5 192.833,76.5 193.5,76.5C 197.933,78.0772 202.433,79.7439 207,81.5C 206.51,85.4959 205.677,89.4959 204.5,93.5C 205.77,98.0435 207.603,102.377 210,106.5C 213.233,103.267 216.4,100.1 219.5,97C 217.05,93.5471 214.217,90.3805 211,87.5C 210.333,86.5 210.333,85.5 211,84.5C 214.981,81.3532 218.814,78.0199 222.5,74.5C 226.833,78.1667 230.833,82.1667 234.5,86.5C 233.018,88.4829 231.351,90.3163 229.5,92C 233.746,91.6333 238.08,91.4666 242.5,91.5 Z'/></g>
<g><path style='opacity:1' fill='#44648e' d='M 185.5,137.5 C 176.083,152.694 163.416,156.194 147.5,148C 136.236,136.725 134.069,123.892 141,109.5C 151.118,96.1683 163.284,94.0016 177.5,103C 187.553,112.735 190.22,124.235 185.5,137.5 Z'/></g>
<g><path style='opacity:1' fill='#f7be8f' d='M 157.5,101.5 C 176.085,102.254 184.585,111.92 183,130.5C 177.22,146.977 166.387,151.811 150.5,145C 137.586,132.293 137.253,119.293 149.5,106C 152.099,104.205 154.766,102.705 157.5,101.5 Z'/></g>
<g><path style='opacity:1' fill='#fefafb' d='M 218.5,111.5 C 219.641,114.64 219.808,117.973 219,121.5C 216.667,124.167 214.333,126.833 212,129.5C 211.333,126.167 211.333,122.833 212,119.5C 214.758,117.249 216.925,114.582 218.5,111.5 Z'/></g>
<g><path style='opacity:1' fill='#fefafb' d='M 218.5,140.5 C 219.75,140.577 220.583,141.244 221,142.5C 221.905,146.819 222.238,151.152 222,155.5C 219,157.167 216,158.833 213,160.5C 212.5,154.175 212.334,147.842 212.5,141.5C 214.735,141.795 216.735,141.461 218.5,140.5 Z'/></g>
<g><path style='opacity:1' fill='#d14359' d='M 238.5,140.5 C 239.5,140.5 240.5,140.5 241.5,140.5C 242.036,143.665 241.203,146.331 239,148.5C 236.423,145.798 236.256,143.131 238.5,140.5 Z'/></g>
<g><path style='opacity:1' fill='#44648e' d='M 246.5,185.5 C 248.288,185.215 249.955,185.548 251.5,186.5C 243.623,199.336 245.29,210.836 256.5,221C 270.808,227.675 281.308,223.841 288,209.5C 291.787,194.574 286.62,184.074 272.5,178C 265.909,176.643 260.076,178.143 255,182.5C 254.506,180.866 254.34,179.199 254.5,177.5C 271.455,169.987 283.955,174.654 292,191.5C 296.556,209.222 290.39,221.388 273.5,228C 253.648,228.822 243.315,219.155 242.5,199C 243.334,194.333 244.667,189.833 246.5,185.5 Z'/></g>
<g><path style='opacity:1' fill='#d79594' d='M 253.5,167.5 C 254.479,170.625 254.813,173.958 254.5,177.5C 254.34,179.199 254.506,180.866 255,182.5C 260.076,178.143 265.909,176.643 272.5,178C 286.62,184.074 291.787,194.574 288,209.5C 281.308,223.841 270.808,227.675 256.5,221C 245.29,210.836 243.623,199.336 251.5,186.5C 249.955,185.548 248.288,185.215 246.5,185.5C 242.958,185.813 239.625,185.479 236.5,184.5C 242.167,184.5 247.833,184.5 253.5,184.5C 253.5,178.833 253.5,173.167 253.5,167.5 Z'/></g>
<g><path style='opacity:1' fill='#42638f' d='M 198.5,189.5 C 198.973,190.906 199.973,191.573 201.5,191.5C 203.5,193.833 205.5,196.167 207.5,198.5C 214.603,212.731 212.27,225.231 200.5,236C 181.295,245.153 168.128,239.653 161,219.5C 159.431,198.077 169.264,187.243 190.5,187C 193.154,187.941 195.821,188.774 198.5,189.5 Z'/></g>
<g><path style='opacity:1' fill='#e8aab7' d='M 198.5,189.5 C 200.027,189.427 201.027,190.094 201.5,191.5C 199.973,191.573 198.973,190.906 198.5,189.5 Z'/></g>
<g><path style='opacity:1' fill='#6f309f' d='M 181.5,190.5 C 194.405,189.574 202.905,195.241 207,207.5C 208.612,229.227 198.778,238.394 177.5,235C 163.633,225.895 160.8,214.061 169,199.5C 172.299,195.118 176.466,192.118 181.5,190.5 Z'/></g>
<g><path style='opacity:1' fill='#e2405b' d='M 172.5,263.5 C 176.291,260.882 179.957,258.049 183.5,255C 192.96,253.91 194.96,257.41 189.5,265.5C 189.833,265.833 190.167,266.167 190.5,266.5C 194.318,263.182 197.985,259.682 201.5,256C 207.519,255.462 209.686,258.295 208,264.5C 204.781,268.052 201.948,271.885 199.5,276C 200.108,276.87 200.941,277.37 202,277.5C 208.714,274.451 213.381,269.451 216,262.5C 217.833,260.667 219.667,258.833 221.5,257C 228.345,254.751 230.679,256.918 228.5,263.5C 232.291,260.882 235.957,258.049 239.5,255C 248.96,253.91 250.96,257.41 245.5,265.5C 245.833,265.833 246.167,266.167 246.5,266.5C 250.318,263.182 253.985,259.682 257.5,256C 263.519,255.462 265.686,258.295 264,264.5C 260.781,268.052 257.948,271.885 255.5,276C 256.108,276.87 256.941,277.37 258,277.5C 263.079,275.421 266.412,271.754 268,266.5C 270.702,261.921 274.202,258.088 278.5,255C 281.482,254.502 284.482,254.335 287.5,254.5C 287.662,256.527 287.495,258.527 287,260.5C 283.547,265.621 279.714,270.454 275.5,275C 277.315,277.27 279.648,277.936 282.5,277C 285.228,274.608 288.228,272.608 291.5,271C 294.5,267.333 297.5,263.667 300.5,260C 297.843,259.825 295.176,259.992 292.5,260.5C 293.045,250.462 298.378,245.962 308.5,247C 310.894,242.43 314.561,239.597 319.5,238.5C 322.693,238.188 323.86,239.522 323,242.5C 321.954,244.09 320.787,245.59 319.5,247C 320.766,247.309 321.933,247.809 323,248.5C 327.097,241.406 332.264,235.239 338.5,230C 340.473,229.505 342.473,229.338 344.5,229.5C 344.774,240.287 341.608,249.953 335,258.5C 330.42,263.338 326.587,268.672 323.5,274.5C 323.712,278.558 325.712,280.058 329.5,279C 330.878,277.287 332.545,275.953 334.5,275C 337.54,267.277 342.207,260.611 348.5,255C 351.939,252.003 355.439,251.837 359,254.5C 359.667,256.167 359.667,257.833 359,259.5C 355.713,265.121 351.379,269.788 346,273.5C 345.333,274.5 345.333,275.5 346,276.5C 355.084,270.752 362.917,263.585 369.5,255C 371.441,254.257 373.274,254.424 375,255.5C 375.667,257.833 375.667,260.167 375,262.5C 371.085,268.021 367.752,273.688 365,279.5C 367.795,277.707 370.295,275.54 372.5,273C 373.793,272.51 375.127,272.343 376.5,272.5C 376.66,274.199 376.494,275.866 376,277.5C 366.601,287.729 357.768,298.396 349.5,309.5C 344.778,311.464 342.445,309.797 342.5,304.5C 345.726,297.393 348.892,290.393 352,283.5C 345.348,289.699 340.348,288.699 337,280.5C 332.892,287.804 326.725,290.637 318.5,289C 316.348,286.531 314.848,283.698 314,280.5C 309.483,285.92 303.816,289.254 297,290.5C 294.648,290.695 292.648,290.028 291,288.5C 290.667,285.5 290.333,282.5 290,279.5C 286.567,284.632 281.9,287.632 276,288.5C 273.7,288.506 271.534,288.006 269.5,287C 267.947,284.345 266.78,281.512 266,278.5C 261.361,283.671 255.861,287.337 249.5,289.5C 247.9,289.449 246.4,289.116 245,288.5C 244.44,284.012 244.773,279.679 246,275.5C 242.535,279.967 238.702,284.133 234.5,288C 232.231,288.758 230.064,288.591 228,287.5C 227.833,286.333 227.667,285.167 227.5,284C 228.583,280.037 229.75,276.204 231,272.5C 226.928,276.983 223.094,281.649 219.5,286.5C 217.579,287.641 215.579,287.808 213.5,287C 211.562,284.53 210.396,281.696 210,278.5C 205.361,283.671 199.861,287.337 193.5,289.5C 191.9,289.449 190.4,289.116 189,288.5C 188.44,284.012 188.773,279.679 190,275.5C 186.535,279.967 182.702,284.133 178.5,288C 171.923,289.591 169.756,287.091 172,280.5C 173.626,277.942 174.626,275.275 175,272.5C 170.928,276.983 167.094,281.649 163.5,286.5C 160.718,287.952 158.218,287.619 156,285.5C 155.178,283.212 154.511,280.878 154,278.5C 151.656,280.774 148.822,281.941 145.5,282C 141.31,288.06 135.643,290.06 128.5,288C 125.538,285.713 123.371,282.88 122,279.5C 113.518,290.145 103.018,297.979 90.5,303C 85.5,303.667 80.5,303.667 75.5,303C 67.7632,299.532 64.4298,293.532 65.5,285C 66.0297,274.411 69.5297,264.911 76,256.5C 85.4052,243.042 97.2385,232.209 111.5,224C 127.454,219.624 132.954,225.457 128,241.5C 123.124,252.386 115.957,261.552 106.5,269C 102.246,272.802 97.7458,273.302 93,270.5C 92.1593,266.88 92.826,263.546 95,260.5C 98.0607,255.771 102.061,252.104 107,249.5C 107.772,249.645 108.439,249.978 109,250.5C 114.053,245.109 117.886,238.943 120.5,232C 118.586,230.173 116.586,230.173 114.5,232C 96.9369,244.559 85.2702,261.226 79.5,282C 80.6183,291.481 85.6183,294.815 94.5,292C 108.112,286.387 118.612,277.221 126,264.5C 132.239,255.536 140.572,252.203 151,254.5C 152.358,257.526 153.191,260.693 153.5,264C 153.165,267.29 152.665,270.456 152,273.5C 156.092,267.734 160.592,262.234 165.5,257C 172.345,254.751 174.679,256.918 172.5,263.5 Z'/></g>
<g><path style='opacity:1' fill='#e3405b' d='M 287.5,239.5 C 294.673,237.839 297.173,240.506 295,247.5C 292.133,251.433 288.467,252.433 284,250.5C 282.662,245.96 283.829,242.293 287.5,239.5 Z'/></g>
<g><path style='opacity:1' fill='#fefffe' d='M 334.5,244.5 C 334.622,247.657 333.455,250.657 331,253.5C 331.559,250.363 332.726,247.363 334.5,244.5 Z'/></g>
<g><path style='opacity:1' fill='#fefffe' d='M 316.5,259.5 C 317.043,259.56 317.376,259.893 317.5,260.5C 316.024,264.404 314.857,268.404 314,272.5C 310.799,276.088 306.965,278.255 302.5,279C 302.043,278.586 301.709,278.086 301.5,277.5C 303.111,272.277 305.277,267.277 308,262.5C 310.714,261.004 313.547,260.004 316.5,259.5 Z'/></g>
<g><path style='opacity:1' fill='#fefffe' d='M 172.5,263.5 C 171.287,266.225 169.454,268.559 167,270.5C 167.772,267.536 169.605,265.202 172.5,263.5 Z'/></g>
<g><path style='opacity:1' fill='#fefffe' d='M 228.5,263.5 C 227.287,266.225 225.454,268.559 223,270.5C 223.772,267.536 225.605,265.202 228.5,263.5 Z'/></g>
<g><path style='opacity:1' fill='#fefffe' d='M 139.5,264.5 C 140.239,264.369 140.906,264.536 141.5,265C 139.85,268.94 139.017,273.107 139,277.5C 136.221,279.797 133.388,279.964 130.5,278C 131.286,275.04 132.452,272.206 134,269.5C 136.191,268.167 138.024,266.5 139.5,264.5 Z'/></g>
</svg>";

    func _getWebpage() : Text {
        var webpage = "<style>" #
        "body { text-align: center; font-family: Arial, sans-serif; background-color: #f0f8ff; color: #333; }" #
        "h1 { font-size: 3em; margin-bottom: 10px; }" #
        "hr { margin-top: 20px; margin-bottom: 20px; }" #
        "em { font-style: italic; display: block; margin-bottom: 20px; }" #
        "ul { list-style-type: none; padding: 0; }" #
        "li { margin: 10px 0; }" #
        "li:before { content: '👉 '; }" #
        "svg { max-width: 150px; height: auto; display: block; margin: 20px auto; }" #
        "h2 { text-decoration: underline; }" #
        "</style>";

        webpage := webpage # "<div><h1>" # name # "</h1></div>";
        webpage := webpage # "<em>" # manifesto # "</em>";
        webpage := webpage # "<div>" # logo # "</div>";
        webpage := webpage # "<hr>";
        webpage := webpage # "<h2>Our goals:</h2>";
        webpage := webpage # "<ul>";
        for (goal in goals.vals()) {
            webpage := webpage # "<li>" # goal # "</li>";
        };
        webpage := webpage # "</ul>";
        return webpage;
    };

    public query func getStats() : async DAOStats {
        return ({
            name;
            manifesto;
            goals = Buffer.toArray(goals);
            members = Iter.toArray(Iter.map<Member, Text>(members.vals(), func(member : Member) { member.name }));
            logo;
            numberOfMembers = members.size();
        });
    };

    public func http_request(request : HttpRequest) : async HttpResponse {
        return ({
            headers = [("Content-Type", "text/html; charset=UTF-8")];
            status_code = 200 : Nat16;
            body = Text.encodeUtf8(_getWebpage());
            streaming_strategy = null;
        });
    };

};