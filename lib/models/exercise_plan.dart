class ExercisePlan {
  final String title;
  final String duration;
  final String focus;
  final List<ExerciseItem> exercises;
  bool isActive;

  ExercisePlan(this.title, this.duration, this.focus, this.exercises, {this.isActive = true});
}

class ExerciseItem {
  final String name;
  final String reps;
  final String sets;
  final String time;
  final String animationUrl;
  bool isCompleted;

  ExerciseItem(this.name, this.reps, this.sets, this.time, this.animationUrl, {this.isCompleted = false});
}