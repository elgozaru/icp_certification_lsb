import Result "mo:base/Result";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Buffer "mo:base/Buffer";
actor MBToken {

  public type Result<A, B> = Result.Result<A, B>;

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

  public query func balanceOf(owner : Principal) : async Nat {
      return (Option.get(ledger.get(owner), 0));
  };

  public query func balanceOfArray(owners : [Principal]) : async [Nat] {
    var balances = Buffer.Buffer<Nat>(0);
    for (owner in owners.vals()) {
        balances.add(Option.get(ledger.get(owner), 0));
    };
    return Buffer.toArray(balances);
  };

  public query func totalSupply() : async Nat {
      var total = 0;
      for (balance in ledger.vals()) {
          total += balance;
      };
      return total;
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
};