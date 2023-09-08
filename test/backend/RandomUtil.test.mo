import { test } "mo:test";
import Rng "../../src/backend/Rng";
import Random "mo:base/Random";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";
import Int "mo:base/Int";

// let randomIntTest = func(min : Int, max : Int, expectedCount : Nat, seed : Blob) {
//     var i = 0;
//     let random = Rng.FiniteRng(Random.Finite(seed));
//     label l loop {
//         switch (random.randomInt(min, max)) {
//             case (null) {
//                 break l;
//             };
//             case (?v) {
//                 if (v < min or v > max) {
//                     Debug.trap("randomInt returned out of range value " # Int.toText(v) # " for min " # Int.toText(min) # " and max " # Int.toText(max) # "");
//                 };
//                 i := i + 1;
//             };
//         };
//     };
//     if (i != expectedCount) {
//         Debug.trap("Expected " #Nat.toText(expectedCount) # " random numbers from entropy, got " # Nat.toText(i));
//     };
// };

test(
    "randomInt",
    func() {
        // randomIntTest(0, 23, 30, "\A1\B2\C3\D4\E5\F6\10\11\12\13\14\15\16\17\18\19\1A\1B\1C\1D\1E\1F\20\21\22\23\24\25\26\27");
        // randomIntTest(0, 10, 20, "\A1\B2\C3\D4\E5\F6\10\11\12\13\14\15\16\17\18\19\1A\1B\1C\1D");
        // randomIntTest(1, 5, 20, "\F1\E2\D3\C4\B5\A6\20\21\22\23\24\25\26\27\28\29\2A\2B\2C\2D");
        // randomIntTest(0, 2, 19, "\01\02\03\04\05\06\07\08\09\0A\0B\0C\0D\0E\0F\10\11\12\13");
        // randomIntTest(-3, 10, 19, "\11\21\31\41\51\61\71\81\91\A1\B1\C1\D1\E1\F1\10\11\12\13");
        // randomIntTest(-4, 30, 18, "\31\32\33\34\35\36\37\38\39\3A\3B\3C\3D\3E\3F\40\41\42");

    },
);
