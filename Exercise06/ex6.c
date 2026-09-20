#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>

#define N 1000000

int main(int argc, char **argv) {
    MPI_Init(&argc, &argv);

    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    int chunk_size = N / size;

    int *array = (int *)malloc(N * sizeof(int));

    if (rank == 0) {
        for (int i = 0; i < N; i++)
            array[i] = i + 1;
        printf("Root filled array with values 1 to %d\n", N);
    }

    int *local_chunk = (int *)malloc(chunk_size * sizeof(int));

    double start = MPI_Wtime();

    // MPI_Bcast(array, N, MPI_INT, 0, MPI_COMM_WORLD);
    MPI_Scatter(array, chunk_size, MPI_INT,
                local_chunk, chunk_size, MPI_INT,
                0, MPI_COMM_WORLD);

    long long local_sum = 0;
    for (int i = 0; i < chunk_size; i++)
        local_sum += local_chunk[i];

    printf("  Rank %d: summed indices [%d, %d) => local_sum = %lld\n",
           rank, 0, chunk_size, local_sum);

    // long long total_sum = 0;

    // MPI_Allreduce(&local_sum, &total_sum, 1, MPI_LONG_LONG, MPI_SUM, MPI_COMM_WORLD);

    long long prefix_sum = 0;
    MPI_Scan(&local_sum, &prefix_sum, 1, MPI_LONG_LONG, MPI_SUM, MPI_COMM_WORLD);

    long long sum_before_me = prefix_sum - local_sum;

    long long K = (long long) (rank + 1) * chunk_size;
    long long expected_prefix = K *(K+1)/2;
    printf("Rank %d: local_sum=%lld, sum_before_me=%lld, prefix_sum=%lld, ",rank, local_sum, sum_before_me, prefix_sum);
    printf("expected=%lld, match=%s\n", expected_prefix, prefix_sum == expected_prefix ? "YES" : "NO");

    double elapsed = MPI_Wtime() - start;

    if(rank == 0){
        long long expected = (long long)N * (N + 1) / 2;
        // printf("\n[Bcast] Total sum   = %lld\n", total_sum);
        // printf("[Bcast] Expected    = %lld\n", expected);
        // printf("[Bcast] Correct?    = %s\n", total_sum == expected ? "YES" : "NO");
        printf("[Bcast] Time        = %.4f sec\n", elapsed);
    }

    if(rank == size - 1){
        long long expected = (long long)N * (N + 1) / 2;
        printf("[Scan] Last rank prefix_sum (global total) = %lld\n", prefix_sum);
        printf("[Scan] Expected global total            = %lld\n", expected);
        printf("[Scan] Correct? = %s\n", prefix_sum == expected ? "YES" : "NO");
    }

    free(array);
    free(local_chunk);
    MPI_Finalize();
    return 0;
}