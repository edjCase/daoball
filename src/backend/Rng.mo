import Random "mo:base/Random";
import Int "mo:base/Int";
import Debug "mo:base/Debug";
import Nat8 "mo:base/Nat8";
import Nat "mo:base/Nat";

module Module {

    public type Rng = {
        randomInt : (min : Int, max : Int) -> Int;
    };

    public class FiniteRng(random : Random.Finite) : Rng {
        public func randomInt(min : Int, max : Int) : Int {
            if (min > max) {
                Debug.trap("Min cannot be larger than max");
            };
            let range : Nat = Int.abs(max - min) + 1;

            var bitsNeeded : Nat = 0;
            var temp : Nat = range;
            while (temp > 0) {
                temp := temp / 2;
                bitsNeeded += 1;
            };

            let ?randVal = random.range(Nat8.fromNat(bitsNeeded)) else Debug.trap("Random number generator is out of entropy"); // TODO
            let randInt = min + (randVal % range);
            randInt;
        };
    };

    public class PseudoRng(seed : Int) : Rng {
        var currentSeed : Int = seed;
        private func randomIntInternal() : Int {
            let a : Int = 1664525;
            let c : Int = 1013904223;
            let m : Int = 4294967296; // 2^32

            currentSeed := (a * currentSeed + c) % m;
            return currentSeed;
        };

        public func randomInt(min : Int, max : Int) : Int {
            let range : Int = max - min + 1;
            let random = randomIntInternal();
            return min + (random % range);
        };
    };

};
