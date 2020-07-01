
# Prep gwas output for plotting
# Stolen from Troy

chr_len <- function(df) {
  df %>%
    # Summarise each chromosome length
    group_by(chr) %>%
    summarise(chr_len = max(pos)) %>%
    # Total relative to entire genome
    mutate(tot = cumsum(chr_len) - chr_len) %>%
    select(-chr_len) %>%
    left_join(df, by = c("chr" = "chr")) %>%
    arrange(chr, pos) %>%
    mutate(BPcum = pos + tot) %>%
    ungroup()
}