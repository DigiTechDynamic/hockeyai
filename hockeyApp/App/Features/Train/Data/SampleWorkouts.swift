import Foundation

struct SampleWorkouts {
    static let all: [Workout] = [
        // MARK: - Elite Shooting Session
        Workout(
            name: "Elite Shooting Session",
            exercises: [
                SampleExercises.all.first(where: { $0.name == "Quick Release Snap Shots" })!,
                SampleExercises.all.first(where: { $0.name == "Top Shelf Corner Accuracy" })!,
                SampleExercises.all.first(where: { $0.name == "Backhand Shelf Shots" })!,
                SampleExercises.all.first(where: { $0.name == "One-Timer Spot Shooting" })!,
                SampleExercises.all.first(where: { $0.name == "Low Blocker Side Shots" })!,
                SampleExercises.all.first(where: { $0.name == "Wrist Shot Rapid Fire" })!
            ],
            estimatedTimeMinutes: 35
        ),

        // MARK: - Stickhandling Mastery
        Workout(
            name: "Stickhandling Mastery",
            exercises: [
                SampleExercises.all.first(where: { $0.name == "Toe Drags" })!,
                SampleExercises.all.first(where: { $0.name == "One-Hand Control Wide Moves" })!,
                SampleExercises.all.first(where: { $0.name == "The Crosby Tight Turns" })!,
                SampleExercises.all.first(where: { $0.name == "Forehand-Backhand Transitions" })!,
                SampleExercises.all.first(where: { $0.name == "Wide-Narrow Pulls" })!,
                SampleExercises.all.first(where: { $0.name == "The Patrick Kane Dribbles" })!,
                SampleExercises.all.first(where: { $0.name == "Tennis Ball Speed Hands" })!
            ],
            estimatedTimeMinutes: 30
        ),

        // MARK: - Speed & Explosiveness
        Workout(
            name: "Speed & Explosiveness",
            exercises: [
                SampleExercises.all.first(where: { $0.name == "Explosive Starts" })!,
                SampleExercises.all.first(where: { $0.name == "Lateral Bounds" })!,
                SampleExercises.all.first(where: { $0.name == "Single-Leg Skater Hops" })!,
                SampleExercises.all.first(where: { $0.name == "5-10-5 Shuttle" })!,
                SampleExercises.all.first(where: { $0.name == "Box Jumps" })!,
                SampleExercises.all.first(where: { $0.name == "Jump Squats" })!,
                SampleExercises.all.first(where: { $0.name == "Diagonal Cuts" })!
            ],
            estimatedTimeMinutes: 25
        ),

        // MARK: - Lower Body Power
        Workout(
            name: "Lower Body Power",
            exercises: [
                SampleExercises.all.first(where: { $0.name == "Goblet Squats" })!,
                SampleExercises.all.first(where: { $0.name == "Bulgarian Split Squats" })!,
                SampleExercises.all.first(where: { $0.name == "Dumbbell Romanian Deadlifts" })!,
                SampleExercises.all.first(where: { $0.name == "Dumbbell Walking Lunges" })!,
                SampleExercises.all.first(where: { $0.name == "Lateral Lunges" })!,
                SampleExercises.all.first(where: { $0.name == "Dumbbell Step-Ups" })!,
                SampleExercises.all.first(where: { $0.name == "Squat Jumps to Box" })!
            ],
            estimatedTimeMinutes: 40
        ),

        // MARK: - Upper Body Strength
        Workout(
            name: "Upper Body Strength",
            exercises: [
                SampleExercises.all.first(where: { $0.name == "Dumbbell Bench Press" })!,
                SampleExercises.all.first(where: { $0.name == "Single-Arm Dumbbell Rows" })!,
                SampleExercises.all.first(where: { $0.name == "Half-Kneeling Shoulder Press" })!,
                SampleExercises.all.first(where: { $0.name == "Explosive Push-Ups" })!,
                SampleExercises.all.first(where: { $0.name == "Renegade Rows" })!,
                SampleExercises.all.first(where: { $0.name == "Plank Shoulder Taps" })!
            ],
            estimatedTimeMinutes: 35
        ),

        // MARK: - Agility & Footwork
        Workout(
            name: "Agility & Footwork",
            exercises: [
                SampleExercises.all.first(where: { $0.name == "Quick Feet Ladder Drill" })!,
                SampleExercises.all.first(where: { $0.name == "Cone Weave Sprint" })!,
                SampleExercises.all.first(where: { $0.name == "T-Drill" })!,
                SampleExercises.all.first(where: { $0.name == "Box Drill" })!,
                SampleExercises.all.first(where: { $0.name == "Figure-8 Cone Sprint" })!,
                SampleExercises.all.first(where: { $0.name == "Lateral Shuffle to Sprint" })!,
                SampleExercises.all.first(where: { $0.name == "Reaction Cone Drill" })!,
                SampleExercises.all.first(where: { $0.name == "Deceleration Drill" })!
            ],
            estimatedTimeMinutes: 30
        ),

        // MARK: - Full Body Conditioning
        Workout(
            name: "Full Body Conditioning",
            exercises: [
                SampleExercises.all.first(where: { $0.name == "Burpees" })!,
                SampleExercises.all.first(where: { $0.name == "Mountain Climbers" })!,
                SampleExercises.all.first(where: { $0.name == "Skater Hops" })!,
                SampleExercises.all.first(where: { $0.name == "Dumbbell Hang Cleans" })!,
                SampleExercises.all.first(where: { $0.name == "Lateral Crossover Lunges" })!,
                SampleExercises.all.first(where: { $0.name == "Single-Leg RDLs" })!,
                SampleExercises.all.first(where: { $0.name == "Backward Running" })!
            ],
            estimatedTimeMinutes: 35
        )
    ]
}
