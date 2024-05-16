import Result "mo:base/Result";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Iter "mo:base/Iter";
import Types "types";
actor {

    type Member = Types.Member;
    type Result<Ok, Err> = Types.Result<Ok, Err>;
    type HashMap<K, V> = Types.HashMap<K, V>;

    // Task #1 : Define an immutable variable members of type Hashmap<Principal,Member> that will be used to store the members of your DAO.
    let members = HashMap.HashMap<Principal, Member>(1, Principal.equal, Principal.hash);

    // Task #2 : Implement the addMember function, this function takes a member of type Member as a parameter, adds a new member to the members HashMap. The function should check if the caller is already a member. If that's the case use a Result type to return an error message.
    public shared ({ caller }) func addMember(member : Member) : async Result<(), Text> {
        if(Principal.isAnonymous(caller)){
            // We don't want to register the anonymous identity
            return #err("Cannot register member with the anonymous identity");
        };

        let optFoundMember : ?Member = members.get(caller);
        switch(optFoundMember) {
            // Check if n is null
            case(null){
                members.put(caller, member);
                return #ok();
            };
            case(? optFoundMember){

                return #err("Member already exists");
            };
            
        }
    };

    // Task #3 : Implement the getMember query function, this function takes a principal of type Principal as a parameter and returns the corresponding member. You will use a Result type for your return value.
    public query func getMember(p : Principal) : async Result<Member, Text> {
        let optFoundMember : ?Member = members.get(p);
        switch(optFoundMember) {
            // Check if n is null
            case(null){
                return #err("Member not found");
            };
            case(? optFoundMember){
                return #ok(optFoundMember);
            };
            
        }
    };

    // Task #4 : Implement the updateMember function, this function takes a member of type Member as a parameter and updates the corresponding member associated with the caller. If the member doesn't exist, return an error message. You will use a Result type for your return value. 
    public shared ({ caller }) func updateMember(member : Member) : async Result<(), Text> {
        switch( members.get(caller) ) {
            // Check if n is null
            case(null){
                return #err("Member not found");
            };
            case(? optFoundMember){
                members.put(caller, member);
                return #ok();
            };
        }
    };

    // Task #5 : Implement the getAllMembers query function, this function takes no parameters and returns all the members of your DAO as an array of type [Member].
    public query func getAllMembers() : async [Member] {
        /*
        return HashMap.toArray<Principal, Member, (Member)>(members, func (k, v) { 
                                                                        v; 
                                                                    });
        */
        return Iter.toArray<(Member)>(members.vals());
    };

    // Task #6 : Implement the numberOfMembers query function, this function takes no parameters and returns the number of members of your DAO as a Nat.
    public query func numberOfMembers() : async Nat {
        return members.size();
    };

    // task #7 : Implement the removeMember function, this function takes no parameter and removes the member associated with the caller. If there is no member associated with the caller, return an error message. You will use a Result type for your return value.
    public shared ({ caller }) func removeMember() : async Result<(), Text> {
        let optFoundMember : ?Member = members.get(caller);
        switch(optFoundMember) {
            // Check if n is null
            case(null){
                return #err("Member not found");
            };
            case(? optFoundMember){
                members.delete(caller);
                return #ok();
            };
        }
    };

};