# Stolen from Troy
# n_genes is top number of genes you want to pull
# window is search space

find_genes <-
  function(df,
           n_genes = 1,
           window = 10000,
           assembly = "umd") {
    # Import Troy's master gene CSV
    genelist <-
      if (assembly == "umd") {
        readr::read_table2(
          here::here("data/raw_data/umd_genes.txt"),
          col_names = c("chr", "start", "stop", "genename", "gene")
        ) %>%
          dplyr::mutate_at(vars(dplyr::contains("gene")), ~ stringr::str_remove_all(., '"')) %>%
          dplyr::mutate(start_range = start - window,
                        stop_range = stop + window,
                        chr = as.numeric(chr),
                        gene = dplyr::if_else(is.na(gene), genename, gene)) %>%
          dplyr::distinct()
      } else if (assembly == "ars") {
        readr::read_csv(
          here::here("data/raw_data/ars_genes.csv"),
          col_names = c("chr", "start", "stop", "gene", "genename")
        ) %>%
          dplyr::mutate(start_range = start - window) %>%
          dplyr::mutate(stop_range = stop + window) %>%
          dplyr::mutate(chr = as.numeric(chr)) %>%
          dplyr::distinct()
      }
    
    glist2 <-
      function(chr_search, pos_search) {
        xx =
          dplyr::filter(genelist, chr == chr_search) %>%
          dplyr::filter(start_range < pos_search) %>%
          dplyr::filter(stop_range > pos_search) %>%
          dplyr::mutate(within = dplyr::case_when(stop > pos_search &
                                                    start < pos_search ~ "YES", #This code checks to see if the SNP is within a gene
                                                  TRUE ~ "NO")) %>%
          dplyr::mutate(chr = chr_search, pos = pos_search) %>%
          dplyr::select(chr, pos, everything())
        return(xx)
      }
    
    purrr::map2(.x = df$chr,
                .y = df$pos,
                ~ glist2(chr_search = .x, pos_search = .y)) %>%
      purrr::reduce(bind_rows) %>%
      dplyr::group_by(gene, chr, pos) %>%
      dplyr::mutate(distance = dplyr::case_when(within == "YES" ~ 0,
                                                TRUE ~ min(abs(start - pos), abs(stop - pos)))) %>%
      dplyr::ungroup() %>%
      dplyr::select(chr, pos, gene, genename, distance) %>%
      dplyr::group_by(chr, pos) %>%
      dplyr::top_n(n_genes, wt = -distance) %>%
      dplyr::ungroup()
  }
