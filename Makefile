CC = mpicc
CFLAGS = -O2 -Wall
NP = 4

# Program names by exercise
EX1_PROG = Exercise01/ex1
EX2_PROG = Exercise02/ex2
EX3_PROG = Exercise03/ex3
EX4_PROG = Exercise04/ex4
EX5_PROG = Exercise05/ex5
EX6_PROG = Exercise06/ex6
EX7_TXT = Exercise07/Exercise07.txt

# Source files
EX1_SRC = Exercise01/ex1.c
EX2_SRC = Exercise02/ex2.c
EX3_SRC = Exercise03/ex3.c
EX4_SRC = Exercise04/ex4.c
EX5_SRC = Exercise05/ex5.c
EX6_SRC = Exercise06/ex6.c

# Default target: compile all exercises
all: $(EX1_PROG) $(EX2_PROG) $(EX3_PROG) $(EX4_PROG) $(EX5_PROG) $(EX6_PROG)
	@echo "✓ All exercises compiled successfully"

# Exercise 1: Broadcast + Send/Recv
$(EX1_PROG): $(EX1_SRC)
	@echo "Compiling Exercise 1 (Bcast)..."
	$(CC) $(CFLAGS) -o $@ $<

# Exercise 2: Scatter + Send/Recv
$(EX2_PROG): $(EX2_SRC)
	@echo "Compiling Exercise 2 (Scatter)..."
	$(CC) $(CFLAGS) -o $@ $<

# Exercise 3: Scatter + Gather
$(EX3_PROG): $(EX3_SRC)
	@echo "Compiling Exercise 3 (Gather)..."
	$(CC) $(CFLAGS) -o $@ $<

# Exercise 4: Scatter + Reduce
$(EX4_PROG): $(EX4_SRC)
	@echo "Compiling Exercise 4 (Reduce)..."
	$(CC) $(CFLAGS) -o $@ $<

# Exercise 5: Scatter + Allreduce
$(EX5_PROG): $(EX5_SRC)
	@echo "Compiling Exercise 5 (Allreduce)..."
	$(CC) $(CFLAGS) -o $@ $<

# Exercise 6: Scatter + Scan
$(EX6_PROG): $(EX6_SRC)
	@echo "Compiling Exercise 6 (Scan)..."
	$(CC) $(CFLAGS) -o $@ $<

# Run all exercises with NP processes
run: all
	@echo ""
	@echo "╔══════════════════════════════════════════════════════════╗"
	@echo "║  Lab 7: MPI Collective Communications - Running All      ║"
	@echo "║  Processes: $(NP)                                               ║"
	@echo "╚══════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "──────────────────────────────────────────────────────────"
	@echo "Exercise 1: Broadcast + Send/Recv"
	@echo "──────────────────────────────────────────────────────────"
	mpirun -np $(NP) $(EX1_PROG)
	@echo ""
	@echo "──────────────────────────────────────────────────────────"
	@echo "Exercise 2: Scatter + Send/Recv"
	@echo "──────────────────────────────────────────────────────────"
	mpirun -np $(NP) $(EX2_PROG)
	@echo ""
	@echo "──────────────────────────────────────────────────────────"
	@echo "Exercise 3: Scatter + Gather"
	@echo "──────────────────────────────────────────────────────────"
	mpirun -np $(NP) $(EX3_PROG)
	@echo ""
	@echo "──────────────────────────────────────────────────────────"
	@echo "Exercise 4: Scatter + Reduce"
	@echo "──────────────────────────────────────────────────────────"
	mpirun -np $(NP) $(EX4_PROG)
	@echo ""
	@echo "──────────────────────────────────────────────────────────"
	@echo "Exercise 5: Scatter + Allreduce"
	@echo "──────────────────────────────────────────────────────────"
	mpirun -np $(NP) $(EX5_PROG)
	@echo ""
	@echo "──────────────────────────────────────────────────────────"
	@echo "Exercise 6: Scatter + Scan"
	@echo "──────────────────────────────────────────────────────────"
	mpirun -np $(NP) $(EX6_PROG)
	@echo ""
	@echo "╔══════════════════════════════════════════════════════════╗"
	@echo "║  All exercises completed                                 ║"
	@echo "╚══════════════════════════════════════════════════════════╝"
	@echo ""

# Run all with different process counts
benchmark: all
	@for np in 2 4 8; do \
		echo ""; \
		echo "╔══════════════════════════════════════════════════════════╗"; \
		echo "║  Running all exercises with $$np processes"; \
		echo "╚══════════════════════════════════════════════════════════╝"; \
		echo ""; \
		echo "Exercise 1 (Bcast):"; mpirun -np $$np $(EX1_PROG) 2>/dev/null | grep -E "(Time|Correct)"; \
		echo "Exercise 2 (Scatter):"; mpirun -np $$np $(EX2_PROG) 2>/dev/null | grep -E "(Time|Correct)"; \
		echo "Exercise 3 (Gather):"; mpirun -np $$np $(EX3_PROG) 2>/dev/null | grep -E "(Time|Correct)"; \
		echo "Exercise 4 (Reduce):"; mpirun -np $$np $(EX4_PROG) 2>/dev/null | grep -E "(Time|Correct)"; \
		echo "Exercise 5 (Allreduce):"; mpirun -np $$np $(EX5_PROG) 2>/dev/null | grep -E "(Time|Correct)"; \
		echo "Exercise 6 (Scan):"; mpirun -np $$np $(EX6_PROG) 2>/dev/null | grep "Rank 3"; \
	done

# Verify correctness of all exercises
verify: all
	@echo "Verifying correctness of all exercises ($(NP) processes)..."
	@echo ""
	@echo "Exercise 1 (Bcast):"; mpirun -np $(NP) $(EX1_PROG) 2>/dev/null | grep "Correct"
	@echo "Exercise 2 (Scatter):"; mpirun -np $(NP) $(EX2_PROG) 2>/dev/null | grep "Correct"
	@echo "Exercise 3 (Gather):"; mpirun -np $(NP) $(EX3_PROG) 2>/dev/null | grep "Correct"
	@echo "Exercise 4 (Reduce):"; mpirun -np $(NP) $(EX4_PROG) 2>/dev/null | grep "Correct"
	@echo "Exercise 5 (Allreduce):"; mpirun -np $(NP) $(EX5_PROG) 2>/dev/null | grep "Correct"
	@echo "Exercise 6 (Scan):"; mpirun -np $(NP) $(EX6_PROG) 2>/dev/null | grep "match=YES" | head -1
	@echo ""

# Run individual exercise (usage: make run-ex1, make run-ex2, etc.)
run-ex1: $(EX1_PROG)
	@echo "Running Exercise 1 (Bcast) with $(NP) processes..."
	mpirun -np $(NP) $(EX1_PROG)

run-ex2: $(EX2_PROG)
	@echo "Running Exercise 2 (Scatter) with $(NP) processes..."
	mpirun -np $(NP) $(EX2_PROG)

run-ex3: $(EX3_PROG)
	@echo "Running Exercise 3 (Gather) with $(NP) processes..."
	mpirun -np $(NP) $(EX3_PROG)

run-ex4: $(EX4_PROG)
	@echo "Running Exercise 4 (Reduce) with $(NP) processes..."
	mpirun -np $(NP) $(EX4_PROG)

run-ex5: $(EX5_PROG)
	@echo "Running Exercise 5 (Allreduce) with $(NP) processes..."
	mpirun -np $(NP) $(EX5_PROG)

run-ex6: $(EX6_PROG)
	@echo "Running Exercise 6 (Scan) with $(NP) processes..."
	mpirun -np $(NP) $(EX6_PROG)

# Clean up compiled binaries
clean:
	@echo "Cleaning up compiled binaries..."
	rm -f $(EX1_PROG) $(EX2_PROG) $(EX3_PROG) $(EX4_PROG) $(EX5_PROG) $(EX6_PROG)
	@echo "✓ Cleanup complete"

# Show help
help:
	@echo "╔══════════════════════════════════════════════════════════╗"
	@echo "║  Lab 7: MPI Collective Communications - Makefile Help     ║"
	@echo "╚══════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "Compilation Targets:"
	@echo "  make all         - Compile all 6 exercises (default)"
	@echo "  make clean       - Remove all compiled binaries"
	@echo ""
	@echo "Execution Targets:"
	@echo "  make run         - Compile and run all exercises ($(NP) processes)"
	@echo "  make NP=8 run    - Run all exercises with 8 processes"
	@echo "  make benchmark   - Run all with 2, 4, 8 processes (timing)"
	@echo "  make verify      - Run all and show correctness results"
	@echo ""
	@echo "Individual Exercise Targets:"
	@echo "  make run-ex1     - Run Exercise 1 (Bcast) only"
	@echo "  make run-ex2     - Run Exercise 2 (Scatter) only"
	@echo "  make run-ex3     - Run Exercise 3 (Gather) only"
	@echo "  make run-ex4     - Run Exercise 4 (Reduce) only"
	@echo "  make run-ex5     - Run Exercise 5 (Allreduce) only"
	@echo "  make run-ex6     - Run Exercise 6 (Scan) only"
	@echo ""
	@echo "Variables:"
	@echo "  NP=n             - Set number of processes (default: $(NP))"
	@echo ""
	@echo "Examples:"
	@echo "  make             - Compile all exercises"
	@echo "  make run         - Run all with 4 processes"
	@echo "  make NP=8 run    - Run all with 8 processes"
	@echo "  make run-ex4     - Run only Exercise 4 (Reduce) with 4 processes"
	@echo "  make benchmark   - Run performance analysis"
	@echo "  make help        - Show this help message"
	@echo ""

.PHONY: all run run-ex1 run-ex2 run-ex3 run-ex4 run-ex5 run-ex6 benchmark verify clean help
