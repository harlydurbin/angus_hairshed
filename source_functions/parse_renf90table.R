
parse_renf90table <-
  function(path, effect) {
    raw <-
      read_lines(path)
    
    rownum <-
      which(str_detect(raw, glue::glue("Effect group {effect}")))
    
    levels <-
      raw[rownum] %>%
      str_extract("(?<=with )[[:digit:]]+(?= levels)") %>%
      as.numeric()
    
    read_table2(
      path,
      skip = rownum + 1,
      n_max = levels,
      col_names = c("id_original", "n", "id_renamed")
    )
    
  }