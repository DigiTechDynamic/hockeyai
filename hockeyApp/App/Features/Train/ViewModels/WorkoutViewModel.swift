import Foundation
import SwiftUI

@MainActor
class WorkoutViewModel: ObservableObject {
    @Published var workouts: [Workout]
    @Published var allExercises: [Exercise]

    private let repository = WorkoutRepository.shared

    init() {
        self.workouts = repository.loadWorkouts()
        self.allExercises = SampleExercises.all
    }

    // MARK: - Workout Management
    func addExercise(_ exercise: Exercise, to workout: Workout) {
        if let index = workouts.firstIndex(where: { $0.id == workout.id }) {
            // Existing workout: just append
            workouts[index].exercises.append(exercise)
        } else {
            // Draft/new workout: create and persist on first add
            var newWorkout = workout
            newWorkout.exercises = [exercise]
            workouts.append(newWorkout)
        }
        repository.saveWorkouts(workouts)
    }

    func removeExercise(at offsets: IndexSet, from workout: Workout) {
        guard let index = workouts.firstIndex(where: { $0.id == workout.id }) else { return }
        workouts[index].exercises.remove(atOffsets: offsets)
        repository.saveWorkouts(workouts)
    }

    func updateExercise(_ exercise: Exercise, in workout: Workout) {
        guard let workoutIndex = workouts.firstIndex(where: { $0.id == workout.id }),
              let exerciseIndex = workouts[workoutIndex].exercises.firstIndex(where: { $0.id == exercise.id }) else {
            return
        }
        workouts[workoutIndex].exercises[exerciseIndex] = exercise
        repository.saveWorkouts(workouts)
    }

    func getWorkout(by id: UUID) -> Workout? {
        workouts.first(where: { $0.id == id })
    }

    func updateWorkoutName(_ name: String, for workout: Workout) {
        guard let index = workouts.firstIndex(where: { $0.id == workout.id }) else { return }
        workouts[index].name = name
        repository.saveWorkouts(workouts)
    }

    // MARK: - Custom Workout Management

    /// Create a new custom workout
    func createWorkout(name: String) -> Workout {
        let newWorkout = Workout(name: name, exercises: [], estimatedTimeMinutes: 0)
        workouts.append(newWorkout)
        repository.saveWorkouts(workouts)
        return newWorkout
    }

    /// Delete a workout
    func deleteWorkout(_ workout: Workout) {
        workouts.removeAll { $0.id == workout.id }
        repository.saveWorkouts(workouts)
    }

    /// Add an existing workout (e.g., featured workout) to user's workouts
    func addWorkout(_ workout: Workout) {
        // Only add if not already present
        guard !workouts.contains(where: { $0.id == workout.id }) else { return }
        workouts.append(workout)
        repository.saveWorkouts(workouts)
    }
}
