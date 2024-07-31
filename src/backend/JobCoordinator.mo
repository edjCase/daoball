import Town "models/Town";
import HashMap "mo:base/HashMap";
import Float "mo:base/Float";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import IterTools "mo:itertools/Iter";
import World "models/World";

module {
    type TownAvailableWork = {
        townId : Nat;
        var goldCanHarvest : Nat;
        var woodCanHarvest : Nat;
        var foodCanHarvest : Nat;
        var stoneCanHarvest : Nat;
    };
    type JobKey = {
        townId : Nat;
        jobId : Nat;
    };

    type JobWithWorkers = {
        town : Town.Town;
        jobId : Nat;
        workers : Nat;
        job : Town.Job;
    };

    public type CalculatedJob = JobWithWorkers and {
        amount : Nat;
    };

    public func calculateJobNumbers(
        towns : [Town.Town],
        locations : HashMap.HashMap<Nat, World.WorldLocation>,
    ) : [CalculatedJob] {
        towns.vals()
        |> Iter.map(_, buildJobsWithWorkerCount)
        |> IterTools.flatten<JobWithWorkers>(_)
        |> Iter.map(
            _,
            func(job : JobWithWorkers) : CalculatedJob {
                let amount = switch (job.job) {
                    // TODO handle case where workers extract more than the resource
                    case (#gatherResource(gatherResourceJob)) getGatherResourceAmount(job.town, job.workers, gatherResourceJob, locations);
                    case (#processResource(processResourceJob)) getProcessResourceAmount(job.town, job.workers, processResourceJob);
                    case (#explore(exploreJob)) getExploreAmount(job.town, job.workers, exploreJob, locations);
                };
                {
                    job with
                    amount = amount;
                };
            },
        )
        |> Iter.toArray(_);
    };

    private func getExploreAmount(
        _ : Town.Town,
        workerCount : Nat,
        _ : Town.ExploreJob,
        _ : HashMap.HashMap<Nat, World.WorldLocation>,
    ) : Nat {
        // TODO proficiency and tech levels?
        workerCount;
    };

    private func getProcessResourceAmount(
        town : Town.Town,
        workerCount : Nat,
        processResourceJob : Town.ProcessResourceJob,
    ) : Nat {
        // TODO levels
        switch (processResourceJob.resource) {
            case (#wood) workerCount + town.skills.carpentry.proficiencyLevel + town.skills.carpentry.techLevel;
            case (#stone) workerCount + town.skills.masonry.proficiencyLevel + town.skills.masonry.techLevel;
        };
    };

    private func getGatherResourceAmount(
        town : Town.Town,
        workerCount : Nat,
        gatherResourceJob : Town.GatherResourceJob,
        locations : HashMap.HashMap<Nat, World.WorldLocation>,
    ) : Nat {
        let ?location = locations.get(gatherResourceJob.locationId) else Debug.trap("Location not found: " # Nat.toText(gatherResourceJob.locationId));

        switch (location.kind) {
            case (#unexplored(_)) Debug.trap("Location is unexplored: " # Nat.toText(gatherResourceJob.locationId));
            case (#standard(standardLocation)) {

                let calculateAmountWithDifficulty = func(workerCount : Int, proficiencyLevel : Nat, techLevel : Nat, difficulty : Nat) : Nat {
                    let baseAmount = workerCount + proficiencyLevel + techLevel;
                    let difficultyScalingFactor = 0.001; // Adjust this value to change the steepness of the linear decrease

                    let scaledDifficulty = Float.fromInt(difficulty) * difficultyScalingFactor;
                    let amountFloat = Float.fromInt(baseAmount) - scaledDifficulty;

                    let amountInt = Float.toInt(amountFloat);
                    if (amountInt <= 1) {
                        1;
                    } else {
                        Int.abs(amountInt);
                    };
                };

                // TODO levels
                switch (gatherResourceJob.resource) {
                    case (#wood) workerCount + town.skills.woodCutting.proficiencyLevel + town.skills.woodCutting.techLevel;
                    case (#food) workerCount + town.skills.farming.proficiencyLevel + town.skills.farming.techLevel;
                    case (#gold) calculateAmountWithDifficulty(
                        workerCount,
                        town.skills.mining.proficiencyLevel,
                        town.skills.mining.techLevel,
                        standardLocation.resources.gold.difficulty,
                    );
                    case (#stone) calculateAmountWithDifficulty(
                        workerCount,
                        town.skills.mining.proficiencyLevel,
                        town.skills.mining.techLevel,
                        standardLocation.resources.stone.difficulty,
                    );
                };
            };
        };

    };

    private func buildJobsWithWorkerCount(town : Town.Town) : Iter.Iter<JobWithWorkers> {
        var remainingPopulation = town.population;
        var totalQuota : Nat = 0;

        let getJobWorkerQuota = func(job : Town.Job) : Nat {
            switch (job) {
                case (#gatherResource(gatherResourceJob)) gatherResourceJob.workerQuota;
                case (#processResource(processResourceJob)) processResourceJob.workerQuota;
                case (#explore(exploreJob)) exploreJob.workerQuota;
            };
        };

        // First, calculate the total quota for all jobs in the town
        for (job in town.jobs.vals()) {
            totalQuota += getJobWorkerQuota(job);
        };

        town.jobs.vals()
        |> IterTools.enumerate(_)
        |> Iter.map<(Nat, Town.Job), JobWithWorkers>(
            _,
            func((jobId, job) : (Nat, Town.Job)) : JobWithWorkers {
                if (totalQuota == 0) {
                    // Handle the case where total quota is 0 to avoid division by zero
                    return {
                        town = town;
                        jobId = jobId;
                        job = job;
                        workers = 0;
                    };
                };

                // Calculate the proportional number of workers for this job
                let workerQuota = getJobWorkerQuota(job);
                // TODO what about rounding?
                let workerCount = (workerQuota * remainingPopulation) / totalQuota;

                // Update remaining population and total quota
                remainingPopulation -= workerCount;
                totalQuota -= workerQuota;

                {
                    town = town;
                    jobId = jobId;
                    job = job;
                    workers = workerCount;
                };
            },
        );
    };
};
