library(readr)
library(dplyr)
library(tidyr)
library(stringr)
library(rlang)
library(glue)
library(ggplot2)
library(forcats)
library(magrittr)
library(tidylog)

source(here::here("source_functions/parse_renf90table.R"))


fixed9_snp1101 <-
  read_table2("C:/Users/agiintern/Downloads/gwas_ssr_fixed9_bvs_p.txt") %>%
  janitor::clean_names() %>%
  mutate(neglog10p = -log10(p_value),
         abs_snp = abs(b_value),
         neglog10q = -log10(qvalue::qvalue(p_value)$qvalues)) %>%
  left_join(read_table2("C:/Users/agiintern/Downloads/gwas_ssr_fixed9_bvs.txt",
                        skip = 12) %>%
              select(chr = Chr, pos = Pos, fdr = FDR_GW, a))


snp_sol %>% 
  filter(chr == 5) %>%
  filter(35000000 >= pos) %>% 
  filter(pos > 10000000) %>% 
  mutate(dataset = "AGI",
         clr = "#009E73") %>% 
  bind_rows(fixed9_snp1101 %>% 
              filter(chr == 5) %>%
              filter(35000000 >= pos) %>% 
              filter(pos > 10000000) %>% 
              mutate(dataset = "Mizzou multibreed",
                     clr = "#0070C0")) %>% 
  ggplot(aes(x = pos,
             y = neglog10p,
             color = clr)) +
  geom_point(alpha = 0.75) +
  scale_color_identity() +
  scale_x_continuous(breaks = c(10000000, 15000000, 20000000, 25000000, 30000000, 35000000),
                     labels = c("10 Mb", "15 Mb", "20 Mb", "25 Mb", "30 Mb", "35 Mb")) +
  theme_classic() +
  theme(axis.title = element_text(size = 18),
        axis.title.y = element_text(margin = margin(t = 0,
                                                    r = 13,
                                                    b = 0,
                                                    l = 0)),
        axis.text = element_text(size = 14),
        legend.text = element_text(size = 14),
        axis.title.x = element_blank(),
        panel.background = element_rect(fill = "transparent",
                                        colour = NA),
        plot.background = element_rect(fill = "transparent",
                                       colour = NA),
        strip.background = element_rect(fill = "transparent",
                                        color = NA),
        strip.text = element_blank()) +
  labs(x = NULL,
       y = latex2exp::TeX("$-log_{10}(p-value)$"),
       title = NULL) +
  geom_hline(yintercept = 5,
             color = "red",
             size = 0.5) +
  facet_wrap(~ dataset,
             scales = "free_y",
             nrow = 2)


ggsave(filename = here::here("figures/agi-mizzou_chr5.p.transparent.png"),
       width = 8,
       height = 6,
       bg = "transparent")

read_table2(
  here::here("data/derived_data/age/years_factor/solutions"),
  skip = 1,
  col_names = c("trait", "effect", "age_renamed", "solution", "se")
) %>%
  filter(effect == 2) %>%
  select(-effect,-trait) %>%
  left_join(
    parse_renf90table(
      path = here::here("data/derived_data/age/years_factor/renf90.tables"),
      effect = 2
    ) %>%
      rename(age = id_original,
             age_renamed = id_renamed)
  ) %>%
  filter(n >= 5) %>%
  arrange(age) %>%
  mutate(age = as_factor(age)) %>%
  ggplot(aes(
    x = age,
    y = solution,
    fill = ifelse(solution > 0, "Highlighted", "Normal")
  )) +
  geom_bar(stat = "identity",
           position = "identity") +
  scale_fill_manual(name = "age",
                    values = c("#009E73", "lightgrey")) +
  geom_errorbar(aes(ymin = solution - se,
                    ymax = solution + se)) +
  theme_classic() +
  theme(
    plot.title = element_blank(),
    axis.title = element_text(size = 18),
    axis.title.y = element_text(margin = margin(
      t = 0,
      r = 10,
      b = 0,
      l = 0
    )),
    axis.title.x = element_text(margin = margin(
      t = 10,
      r = 0,
      b = 0,
      l = 0
    )),
    axis.text = element_text(size = 14),
    legend.position = "none",
    plot.margin = margin(
      t = 5,
      r = 0,
      b = 0,
      l = 0
    ),
    panel.background = element_rect(fill = "transparent",
                                    colour = NA),
    plot.background = element_rect(fill = "transparent",
                                   colour = NA)
  ) +
  labs(x = "Age in years",
       y = "Effect estimate",
       title = NULL)

ggsave(filename = here::here("figures/age_defense.transparent.png"),
       width = 6,
       height = 4,
       bg = "transparent")
