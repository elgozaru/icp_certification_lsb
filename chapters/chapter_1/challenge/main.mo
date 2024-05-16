import Buffer "mo:base/Buffer";
import Text "mo:base/Text";
actor {

    // Task #1:
    // Define an immutable variable name of type Text that represents the name of your DAO.
    let name : Text = "Commitly";

    // Task #2:
    // Define a mutable variable manifesto of type Text that represents the manifesto of your DAO.
    var manifesto : Text = "I want people to get a good level of financial litteracy and understand the value of having the capacity to create currency in our society, so they can foresee a future living in diverse autonomous and resilient communities and have the conviction they can build it by themselves with the proper tools without having to be a Tech or Economics well versed group. \nI see the society leveraging the best features of Local Currencies and Web3 technologies (Web, Blockchain, AI) to foster collective collaboration in new fast growing and sustainable economies without the need of direct intervention from superior public or private third party, as well as reinforcing understanding of global problems and social cohesion through the Metaverse. \nBy having unlimited ressources, I'd guide the creation of thousands of communitites with an emergent yet evolving DAO protocol, helping them to reach maturity in exchanging services / products / infrastructure and automating the creation of synergies between complimentary communities. With the backing of a community, I'll start to test my protocol with three first communities of different kinds: volunteering, local stores loyalty programs with a decentralized voucher/(local currency) trade marketplace, co-property landlords association, to see how they evolve and create policies / currency management according to their own needs, then once mature extend the experience to public and private organizations willing to experiment with notions like participative budget and get insights about the strenghts and needs of targeted communities regarding wise investments and informed marketing campaigns that respect the protection of local culture and development of human / sustainable values; finally I'd create a federation of mature DAO LLC communities to share best practices and local economics models with the help of AI automation, so they can either become official local banks or be able to provide a complete ecosysteme of services, products and infrastructure needed for sustainable human development, like cells living in symbiosis at different levels and aspects without the complexity of a multilayer hierarchical structure";

    // task #3 : Implement the getName query function, this function takes no parameters and returns the name of your DAO.
    public shared query func getName() : async Text {
        return name;
    };

    // Task #4 : Implement the getManifesto query function, this function takes no parameters and returns the manifesto of your DAO.
    public shared query func getManifesto() : async Text {
        return manifesto;
    };

    // Task #5 : Implement the setManifesto function, this function takes a newManifesto of type Text as a parameter, updates the value of manifesto and returns nothing.
    public func setManifesto(newManifesto : Text) : async () {
        manifesto := newManifesto;
        return;
    };

    // Task #6 : Define a mutable variable goals of type Buffer<Text> will store the goals of your DAO.
    var goals : Buffer.Buffer<Text> = Buffer.Buffer<Text>(2); 
    //goals.add("#1 : Have a prototype and three different pilot communities to test on a low or null fee blockchain/Web3");
    //goals.add("#2 : Have a full product (voting, services management, data aggregation) for promoting investment insights and three different mature communities to use as reference for newer communities");
    //goals.add("#3 : Have extended features (NFT content rewards, social media / gaming partners to reflect the activity of each community on the metaverse) for promoting social cohesion / motivation to participate within financially autonomous communities and 50 new different community types to use as candidates for synergies");
    //goals.add("#4 : Have extended management tools (automated and legally compliant accountability for local currency management, AI to detect synergies and export economic model) for growth acceleration of candidate mature communities for federative synergy structure / global currency and the recognition of public insitutions for them to operate and expand operations to infrastructure and banking capabilities");


    // Task #7 : Implement the addGoal function, this function takes a goal of type Text as a parameter, adds a new goal to the goals buffer and returns nothing.
    public func addGoal(newGoal : Text) : async () {
        goals.add(newGoal);
        return;
    };

    // Task #8 : Implement the getGoals query function, this function takes no parameters and returns all the goals of your DAO in an Array. 
    public shared query func getGoals() : async [Text] {
        return Buffer.toArray<Text>(goals);
    };
};