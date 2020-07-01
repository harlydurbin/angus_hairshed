
melt_hair_weights <-
  function(path, full_ped){
    
    start <-
      read_csv(path) %>% 
      filter(is_et == FALSE) %>%
      rename(full_reg = reg_num) %>% 
      mutate_at(vars(contains("dt")), ~ lubridate::mdy(.)) %>% 
      mutate(full_reg = str_remove_all(full_reg, "[:blank:]")) %>% 
      left_join(full_ped) 
   
    
    # Birth
     b <-
      start %>% 
      select(contains("reg"), contains("birth"), sex, dob) %>% 
      mutate(trait = "bw") %>% 
      rename(cg_num = birth_cg_num,
             weigh_date = anm_birth_dt,
             unadj_weight = birth_wt, 
             adj_weight = birth_adj_wt)
   
    # Weaning 
    w <-
      start %>% 
      select(contains("reg"), contains("wn"), sex, dob) %>% 
      mutate(trait = "ww") %>% 
      rename(cg_num = wn_cg_num,
             weigh_date = wn_weigh_dt,
             unadj_weight = wn_wt, 
             adj_weight = wn_adj_wt)
    
    # Yearling
    y <-
      start %>% 
      select(contains("reg"), contains("yr"), sex, dob) %>% 
      mutate(trait = "yw") %>% 
      rename(cg_num = yr_cg_num,
             weigh_date = yr_weigh_dt,
             unadj_weight = yr_wt, 
             adj_weight = yr_adj_wt)
    
    
    bind_rows(b, w, y) %>% 
      filter(!is.na(adj_weight))
    
  }