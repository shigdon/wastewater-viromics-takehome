#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(stringr)
  library(readr)
})

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 2) {
  stop(
    "Usage: Rscript workflow/scripts/make_samples_htp.R <input_csv> <output_csv>",
    call. = FALSE
  )
}

input_csv <- args[1]
output_csv <- args[2]

htp <- read_csv(input_csv, show_col_types = FALSE)

target_dates <- c(
  "2020-11-03",
  "2020-11-24",
  "2020-12-04",
  "2020-12-22",
  "2021-01-03"
)

samples_htp <- htp %>%
  mutate(
    mm = str_match(SampleName, "HTP_(\\d{1,2})_(\\d{1,2})_(\\d{2,4})")[, 2],
    dd = str_match(SampleName, "HTP_(\\d{1,2})_(\\d{1,2})_(\\d{2,4})")[, 3],
    yy = str_match(SampleName, "HTP_(\\d{1,2})_(\\d{1,2})_(\\d{2,4})")[, 4],
    yy = if_else(!is.na(yy) & nchar(yy) == 2, paste0("20", yy), yy),
    date = if_else(
      !is.na(mm) & !is.na(dd) & !is.na(yy),
      sprintf("%04d-%02d-%02d", as.integer(yy), as.integer(mm), as.integer(dd)),
      NA_character_
    ),
    treatment = case_when(
      str_detect(SampleName, "INF_unenriched") ~ "unenriched",
      LibraryStrategy == "Targeted-Capture" ~ "enriched",
      TRUE ~ "unknown"
    ),
    site = "HTP",
    matrix = case_when(
      str_detect(SampleName, "INF") ~ "INF",
      TRUE ~ "unknown"
    )
  ) %>%
  filter(
    !is.na(date),
    date %in% target_dates,
    treatment %in% c("enriched", "unenriched")
  ) %>%
  transmute(
    sample_id = paste0("HTP_", date, "_", treatment),
    site,
    date,
    treatment,
    matrix,
    srr = Run,
    biosample = BioSample,
    library_strategy = LibraryStrategy,
    library_source = LibrarySource,
    layout = LibraryLayout
  ) %>%
  distinct() %>%
  arrange(date, treatment)

if (nrow(samples_htp) != 10) {
  stop(
    paste0(
      "Expected 10 samples (5 enriched/unenriched pairs), but found ",
      nrow(samples_htp),
      ". Check input metadata and filtering logic."
    ),
    call. = FALSE
  )
}

dir.create(dirname(output_csv), recursive = TRUE, showWarnings = FALSE)
write_csv(samples_htp, output_csv)