module {

    public type MatchAura = {
        #lowGravity;
        #explodingBalls;
        #fastBallsHardHits;
        #moreBlessingsAndCurses;
        #moveBasesIn;
        #doubleOrNothing;
    };

    public type MatchAuraMetaData = {
        name : Text;
        description : Text;
    };

    public type MatchAuraWithMetaData = MatchAuraMetaData and {
        aura : MatchAura;
    };

    public func hash(aura : MatchAura) : Nat32 = switch (aura) {
        case (#lowGravity) 0;
        case (#explodingBalls) 1;
        case (#fastBallsHardHits) 2;
        case (#moreBlessingsAndCurses) 3;
        case (#moveBasesIn) 4;
        case (#doubleOrNothing) 5;
    };

    public func equal(a : MatchAura, b : MatchAura) : Bool = a == b;

    public func getMetaData(aura : MatchAura) : MatchAuraMetaData {
        switch (aura) {
            case (#lowGravity) {
                {
                    name = "Low Gravity";
                    description = "Balls fly farther and players jump higher.";
                };
            };
            case (#explodingBalls) {
                {
                    name = "Exploding Balls";
                    description = "Balls have a chance to explode on contact with the bat.";
                };
            };
            case (#fastBallsHardHits) {
                {
                    name = "Fast Balls, Hard Hits";
                    description = "Balls are faster and fly farther when hit by the bat.";
                };
            };
            case (#moreBlessingsAndCurses) {
                {
                    name = "More Blessings And Curses";
                    description = "Blessings and curses are more common.";
                };
            };
            case (#moveBasesIn) {
                {
                    name = "Move Bases In";
                    description = "Bases are closer together.";
                };
            };
            case (#doubleOrNothing) {
                {
                    name = "Double Or Nothing";
                    description = "Hits count for double points, but strikeouts lose points.";
                };
            };
        };
    };
};
