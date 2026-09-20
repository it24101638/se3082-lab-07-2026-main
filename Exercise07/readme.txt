# Exercise 7: Summary Comparison of All 6 Programs

## Part 1: Comparative Table

| Aspect | Ex 1: Bcast | Ex 2: Scatter | Ex 3: Gather | Ex 4: Reduce | Ex 5: Allreduce | Ex 6: Scan |
|--------|-------------|---------------|--------------|--------------|-----------------|-----------|
| **Collectives Used** | Bcast + Send/Recv | Scatter + Send/Recv | Scatter + Gather | Scatter + Reduce | Scatter + Allreduce | Scatter + Scan |
| **Distribution Phase** | Broadcast full array | Scatter chunks | Scatter chunks | Scatter chunks | Scatter chunks | Scatter chunks |
| **Array Allocation** | Every process allocs full (N) | Root allocs full (N), others alloc chunk (N/size) | Root allocs full (N), others alloc chunk (N/size) | Root allocs full (N), others alloc chunk (N/size) | Root allocs full (N), others alloc chunk (N/size) | Root allocs full (N), others alloc chunk (N/size) |
| **Collection Phase** | Manual Send/Recv loop | Manual Send/Recv loop | Single Gather call | Single Reduce call | Single Allreduce call | Single Scan call |
| **Manual Summation** | YES (in Send/Recv loop) | YES (in Send/Recv loop) | YES (root loops all_sums[]) | NO (Reduce computes) | NO (Allreduce computes) | NO (Scan computes) |
| **Result on Root Only** | YES | YES | YES | YES | NO | NO |
| **Result on All Processes** | NO | NO | NO | NO | YES (all identical) | YES (each different) |
| **Result Structure** | Single total_sum (root only) | Single total_sum (root only) | Array all_sums[] (root only) | Single total_sum (root only) | Single total_sum (all processes) | Different prefix_sum per rank |
| **Algorithmic Complexity** | O(P) - sequential | O(P) - sequential | O(P) - sequential | O(log P) - tree | O(log P) - tree | O(log P) - tree |
| **Use Case** | Broadcast data then manual collection | Distribute chunks then manual collection | Distribute chunks, collect all values for analysis | Distribute chunks, compute global aggregate | Distribute chunks, all processes need global result | Distribute chunks, compute cumulative results |

---

## Part 2: Timing Analysis

### How to Run Benchmarks

```bash
# Compile all programs
mpicc -O2 -o sum_bcast sum_bcast.c        # Ex 1 (create from original ex1.c if needed)
mpicc -O2 -o sum_scatter sum_scatter.c    # Ex 2
mpicc -O2 -o sum_gather sum_gather.c      # Ex 3
mpicc -O2 -o sum_reduce sum_reduce.c      # Ex 4
mpicc -O2 -o sum_allreduce sum_allreduce.c  # Ex 5
mpicc -O2 -o sum_scan sum_scan.c          # Ex 6

# Run with different process counts (2, 4, 8)
for np in 2 4 8; do
  echo "=== Running with $np processes ==="
  mpirun -np $np ./sum_bcast | grep "Time"
  mpirun -np $np ./sum_scatter | grep "Time"
  mpirun -np $np ./sum_gather | grep "Time"
  mpirun -np $np ./sum_reduce | grep "Time"
  mpirun -np $np ./sum_allreduce | grep "Time"
  mpirun -np $np ./sum_scan | grep "Time"
done
```

### Expected Timing Results

| Program | 2 Processes | 4 Processes | 8 Processes |
|---------|-------------|-------------|-------------|
| **Ex 1: Bcast** | ~0.015 sec | ~0.020 sec | ~0.030 sec |
| **Ex 2: Scatter** | ~0.012 sec | ~0.015 sec | ~0.025 sec |
| **Ex 3: Gather** | ~0.010 sec | ~0.012 sec | ~0.020 sec |
| **Ex 4: Reduce** | ~0.010 sec | ~0.012 sec | ~0.020 sec |
| **Ex 5: Allreduce** | ~0.010 sec | ~0.012 sec | ~0.020 sec |
| **Ex 6: Scan** | ~0.010 sec | ~0.012 sec | ~0.020 sec |

**General Trend:**
- **Ex 1 (Bcast):** Slowest — wastes memory, sequential Send/Recv
- **Ex 2 (Scatter):** Faster than Ex 1 — less data broadcast, but still sequential Send/Recv
- **Ex 3-6 (Scatter + Collective):** Fastest group — tree-based algorithms O(log P)
- **Timing increases with process count:** More processes = more communication overhead

**Why Collective > Send/Recv:**
- Collective operations use **tree-based reduction** → O(log P) steps
- Manual loops use **sequential pairing** → O(P) steps
- Example: 8 processes
  - Send/Recv: 7 sequential receives
  - Tree reduction: ⌈log₂ 8⌉ = 3 levels of parallelism

---

## Part 3: Key Observations

### Memory Efficiency Ranking
1. **Ex 6 (Scan):** ✓✓✓ Chunk allocation only, no extra arrays
2. **Ex 4 (Reduce):** ✓✓✓ Chunk allocation only, single result variable
3. **Ex 5 (Allreduce):** ✓✓✓ Chunk allocation only, single result variable
4. **Ex 3 (Gather):** ✓✓ Chunk allocation + all_sums[] array on root
5. **Ex 2 (Scatter):** ✓ Chunk allocation, sequential Send/Recv
6. **Ex 1 (Bcast):** ✗ Every process allocates full array!

### Communication Efficiency Ranking
1. **Ex 4 (Reduce):** ✓✓✓ Optimized tree algorithm, result on root only
2. **Ex 5 (Allreduce):** ✓✓✓ Optimized tree algorithm, broadcasts to all (slight overhead)
3. **Ex 6 (Scan):** ✓✓✓ Optimized tree algorithm, different per rank
4. **Ex 3 (Gather):** ✓✓ Tree-based if lucky, otherwise sequential
5. **Ex 2 (Scatter):** ✓ Sequential Send/Recv (many messages)
6. **Ex 1 (Bcast):** ✗ One large broadcast (N elements to all)

---

## Part 4: Thinking Question

**Q: In what situation would you choose MPI_Scan over MPI_Allreduce? Give a concrete example.**

### Answer

**Choose MPI_Scan when:** Each process needs a **different** result based on **its rank position**, specifically the cumulative computation from rank 0 through that rank.

**Concrete Example: Global Index Assignment for Load Balancing**

Scenario: You have 4 processes, each computed different amounts of work:
- Rank 0: processed 1000 items
- Rank 1: processed 1500 items
- Rank 2: processed 800 items
- Rank 3: processed 2000 items

**If you use Allreduce:**
```c
MPI_Allreduce(&local_count, &total_items, 1, MPI_INT, MPI_SUM, MPI_COMM_WORLD);
// All ranks: total_items = 5300

// Every rank knows the TOTAL, but:
// - Rank 1 doesn't know where its results fit in the global array!
// - Rank 2 doesn't know where its results fit in the global array!
// - Rank 3 doesn't know where its results fit in the global array!
```

**If you use Scan (correct choice):**
```c
long long local_count = /* items processed by this rank */;
long long prefix_sum = 0;
MPI_Scan(&local_count, &prefix_sum, 1, MPI_LONG_LONG, MPI_SUM, MPI_COMM_WORLD);

long long my_offset = prefix_sum - local_count;  // Where to write results globally

// Rank 0: my_offset = 0,    prefix_sum = 1000    (write to indices 0-999)
// Rank 1: my_offset = 1000, prefix_sum = 2500    (write to indices 1000-2499)
// Rank 2: my_offset = 2500, prefix_sum = 3300    (write to indices 2500-3299)
// Rank 3: my_offset = 3300, prefix_sum = 5300    (write to indices 3300-5299)
```

**Without any additional communication,** each rank now knows exactly where to write its results in the global output array!

**Other Real-World Use Cases for Scan:**
1. **Global numbering:** Assign unique IDs across all processes
2. **Prefix sum arrays:** Compute cumulative distribution
3. **Load-balanced scheduling:** Each process knows which tasks to execute globally
4. **Graph partitioning:** Determine global vertex IDs for distributed graph algorithms
5. **Cumulative histograms:** Build a global histogram from local contributions

**Summary:**
- **Allreduce:** "What's the total?" → Same answer on all processes
- **Scan:** "What's my part?" → Different answer per rank, with ordering information

---

## Part 5: Comprehensive Recommendation Matrix

| Scenario | Best Choice | Reason |
|----------|-------------|--------|
| Need total on root only | **Reduce** | Fastest, root-only result |
| All processes need same total | **Allreduce** | Every process gets global answer |
| Need global offsets/indices | **Scan** | Each rank gets cumulative position |
| Collect all values for analysis | **Gather** | Can inspect individual contributions |
| Broadcast then process | **Bcast** | Simple but memory-wasteful |
| Distribute then process manually | **Scatter + Send/Recv** | Avoid! Collective is faster |

---

## Summary Statistics

**Number of MPI calls (distribution + collection):**
- Ex 1: 2 major phases (Bcast + loop of Send/Recv) = O(P) calls
- Ex 2: 2 major phases (Scatter + loop of Send/Recv) = O(P) calls
- Ex 3: 2 major phases (Scatter + Gather) = 2 calls
- Ex 4: 2 major phases (Scatter + Reduce) = 2 calls
- Ex 5: 2 major phases (Scatter + Allreduce) = 2 calls
- Ex 6: 2 major phases (Scatter + Scan) = 2 calls

**Best overall:** Tie between Ex 4, 5, 6 (fewest calls, fastest algorithms)