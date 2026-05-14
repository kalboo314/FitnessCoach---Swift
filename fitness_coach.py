import os
from crewai import Agent, Task, Process, Crew, LLM
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# ============================================
# CONFIGURE THE LLM (Using Groq's free tier)
# ============================================
llm = LLM(
    model="groq/llama-3.3-70b-versatile",
    base_url="https://api.groq.com/openai/v1",
    api_key=os.environ.get("GROQ_API_KEY"),
    temperature=0.7
)

# ============================================
# CREATE SPECIALIZED AGENTS
# ============================================

# Agent 1: Fitness Assessment Specialist
assessor = Agent(
    role='Fitness Assessment Specialist',
    goal='Analyze user profile and determine optimal fitness approach',
    verbose=True,
    llm=llm,
    backstory="""You are an expert fitness assessor with 15 years of experience. 
    You specialize in understanding different body types, fitness levels, and goals. 
    You know how to assess injuries, limitations, and motivation levels. 
    You provide honest, safe recommendations and never push beyond reasonable limits."""
)

# Agent 2: Workout Program Designer
workout_planner = Agent(
    role='Certified Personal Trainer',
    goal='Design safe, effective, and progressive workout routines',
    verbose=True,
    llm=llm,
    backstory="""You are a certified personal trainer (CPT) with expertise in strength training, 
    cardio conditioning, HIIT, calisthenics, and mobility work. You understand exercise science, 
    proper form, injury prevention, and progressive overload. You create workouts that are 
    challenging but achievable, with clear instructions and modifications for different levels."""
)

# Agent 3: Nutrition & Meal Prep Expert
nutritionist = Agent(
    role='Registered Dietitian',
    goal='Create practical, healthy meal plans and prep strategies',
    verbose=True,
    llm=llm,
    backstory="""You are a registered dietitian specializing in fitness nutrition, meal prep, 
    and sustainable eating habits. You understand macronutrients, meal timing, portion control, 
    and how to work within different dietary restrictions (vegan, keto, vegetarian, halal, etc.). 
    You provide realistic, budget-friendly meal prep advice that people can actually stick to."""
)

# Agent 4: Schedule & Recovery Coach
schedule_coach = Agent(
    role='Training Schedule & Recovery Specialist',
    goal='Create balanced weekly schedules with proper recovery',
    verbose=True,
    llm=llm,
    backstory="""You are an expert in periodization, training frequency, and recovery science. 
    You know how to balance workouts, rest days, active recovery, and sleep. You understand 
    how to fit fitness into busy schedules and prevent burnout or overtraining."""
)

# Agent 5: Motivational Coach (Executive)
motivator = Agent(
    role='Executive Fitness Motivator',
    goal='Synthesize all plans into an actionable, encouraging program',
    verbose=True,
    llm=llm,
    backstory="""You are an executive coach who specializes in turning complex fitness plans 
    into simple, daily actions. You're encouraging but realistic. You help people build 
    sustainable habits and celebrate small wins. You tie everything together into a 
    easy-to-follow weekly blueprint."""
)

# ============================================
# DEFINE THE TASKS
# ============================================

assessment_task = Task(
    description="""
    Analyze the following user profile and provide a comprehensive fitness assessment:
    
    - Fitness Goal: {goal}
    - Current Fitness Level: {level} (beginner/intermediate/advanced)
    - Age: {age}
    - Weight: {weight} kg
    - Height: {height} cm
    - Available Workout Days: {days} days per week
    - Available Time per Session: {time} minutes
    - Equipment Available: {equipment}
    - Dietary Preference: {diet_type}
    - Injuries/Limitations: {injuries}
    
    Provide:
    1. Realistic assessment of their current state
    2. Recommended training focus (strength, cardio, flexibility, etc.)
    3. Any safety considerations based on injuries/limitations
    4. Estimated timeline to see meaningful results
    """,
    expected_output="""A detailed fitness assessment including: 
    - Current state analysis
    - Recommended training focus areas
    - Safety considerations
    - Realistic timeline expectations""",
    agent=assessor
)

workout_task = Task(
    description="""
    Using the assessment provided, create a detailed workout routine.
    
    Requirements:
    - {days} days per week schedule
    - {time} minutes per session
    - Equipment available: {equipment}
    - Include warm-up, main workout, and cool-down for each session
    - Specify sets, reps, rest periods, and intensity (RPE)
    - Include modifications for different fitness levels
    
    Make exercises specific and actionable (e.g., "3 sets of 10 push-ups" not just "push-ups").
    """,
    expected_output="""A complete {days}-day weekly workout plan with:
    - Day-by-day breakdown
    - Specific exercises with sets, reps, and rest
    - Warm-up and cool-down instructions
    - Progression recommendations""",
    agent=workout_planner,
    context=[assessment_task]
)

nutrition_task = Task(
    description="""
    Using the assessment, create a practical meal prep plan.
    
    Requirements:
    - Diet type: {diet_type}
    - Goal: {goal} (weight loss/muscle gain/maintenance)
    - Create a sample day of eating
    - Provide 3-5 meal prep recipes that are:
      * Easy to batch cook
      * Budget-friendly
      * Takes < 2 hours prep for the week
    - Include grocery shopping list
    
    Focus on whole foods, not supplements.
    """,
    expected_output="""A practical meal prep guide including:
    - Sample daily meal schedule
    - 3-5 batch cook recipes with ingredients and instructions
    - Weekly grocery shopping list
    - Portion guidance""",
    agent=nutritionist,
    context=[assessment_task]
)

schedule_task = Task(
    description="""
    Create a comprehensive weekly schedule integrating workouts, meal prep, and recovery.
    
    Requirements:
    - Fit {days} workout days into a realistic weekly calendar
    - Schedule meal prep day/time
    - Include recovery strategies (sleep, stretching, rest days)
    - Suggest optimal workout times based on typical energy patterns
    - Include contingency plans for busy days
    
    Make it realistic for someone with a job/other commitments.
    """,
    expected_output="""A day-by-day weekly schedule including:
    - Workout times and types
    - Meal prep timing
    - Recovery activities
    - Sleep recommendations
    - Backup plans for missed workouts""",
    agent=schedule_coach,
    context=[assessment_task, workout_task, nutrition_task]
)

final_plan_task = Task(
    description="""
    Synthesize the assessment, workout plan, meal plan, and schedule into a 
    complete, actionable fitness program.
    
    Present it as a professional, encouraging "Fitness Blueprint" that the user can 
    follow immediately. Include:
    
    1. Executive Summary (1-2 paragraphs)
    2. Weekly Workout Schedule (day-by-day)
    3. Detailed Exercise Instructions
    4. Meal Prep Guide & Recipes
    5. Recovery & Sleep Recommendations
    6. First Week Action Plan (Day 1 specific instructions)
    7. Motivation tips & milestone tracking
    
    Make it inspiring but realistic. Use friendly, encouraging language.
    """,
    expected_output="""A complete fitness blueprint in markdown format:
    - Clear sections with headers
    - Day-by-day workout instructions
    - Recipes with ingredients and steps
    - Actionable first-week plan
    - Motivational closing section""",
    agent=motivator,
    context=[assessment_task, workout_task, nutrition_task, schedule_task]
)

# ============================================
# CREATE THE CREW
# ============================================
fitness_crew = Crew(
    agents=[assessor, workout_planner, nutritionist, schedule_coach, motivator],
    tasks=[assessment_task, workout_task, nutrition_task, schedule_task, final_plan_task],
    process=Process.sequential,
    verbose=True
)

# ============================================
# GET USER INPUT
# ============================================
print("\n" + "="*60)
print("🏋️‍♂️  WELCOME TO YOUR AI FITNESS COACH  🏋️‍♀️")
print("="*60)
print("\nAnswer a few questions to get your personalized fitness blueprint.\n")

# Collect user information
goal = input("What's your primary goal? (weight loss/muscle gain/improve fitness/maintain): ").strip()
level = input("Current fitness level? (beginner/intermediate/advanced): ").strip()
age = input("Age: ").strip()
weight = input("Weight (kg): ").strip()
height = input("Height (cm): ").strip()
days = input("How many days per week can you workout? (1-7): ").strip()
time = input("Minutes per workout session? (15-90): ").strip()
equipment = input("Equipment available? (bodyweight only/dumbbells/barbell/machine/full gym): ").strip()
diet_type = input("Dietary preference? (omnivore/vegetarian/vegan/kosher/halal/keto): ").strip()
injuries = input("Any injuries or limitations? (none/knee/back/shoulder/other): ").strip()

print("\n" + "="*60)
print("🎯 Generating your personalized fitness blueprint...")
print("="*60 + "\n")

# ============================================
# RUN THE CREW
# ============================================
result = fitness_crew.kickoff(
    inputs={
        'goal': goal,
        'level': level,
        'age': age,
        'weight': weight,
        'height': height,
        'days': days,
        'time': time,
        'equipment': equipment,
        'diet_type': diet_type,
        'injuries': injuries
    }
)

# ============================================
# DISPLAY THE RESULT
# ============================================
print("\n" + "="*60)
print("📋 YOUR PERSONALIZED FITNESS BLUEPRINT 📋")
print("="*60)
print(result)
print("\n" + "="*60)
print("💪 Stay consistent! Your AI coach is here when you need adjustments. 💪")
print("="*60)

# ============================================
# SAVE TO FILE
# ============================================
with open('fitness_blueprint.md', 'w') as f:
    f.write(f"# Fitness Blueprint for {age}yo {goal} journey\n\n")
    f.write(f"**Generated on:** {__import__('datetime').datetime.now().strftime('%Y-%m-%d %H:%M')}\n\n")
    f.write(f"**User Profile:** {level} level, {weight}kg, {height}cm\n\n")
    f.write("---\n\n")
    f.write(str(result))

print("\n✅ Your blueprint has been saved to 'fitness_blueprint.md'")