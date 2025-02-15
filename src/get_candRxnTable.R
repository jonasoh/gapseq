library(getopt)
suppressMessages(library(stringr))
suppressMessages(library(stringi))
suppressMessages(library(R.utils))
library(methods)
options(error=traceback)

# get current script path
if (!is.na(Sys.getenv("RSTUDIO", unset = NA))) {
  # RStudio specific code
  script.dir    <- dirname(rstudioapi::getSourceEditorContext()$path)
} else{
  initial.options <- commandArgs(trailingOnly = FALSE)
  script.name <- sub("--file=", "", initial.options[grep("--file=", initial.options)])
  script.dir  <- dirname(script.name)
}

source(paste0(script.dir,"/prepare_candidate_reaction_tables.R"))

# get options first
spec <- matrix(c(
  'blast.res', 'r', 1, "character", "Blast-results table generated by gapseq.sh.",
  'transporter.res', 't', 1, "character", "Blast-results table generated by transporter.sh.",
  'model.name', 'n', 2, "character", "Name of draft model network. Default: the basename of \"blast.res\"",
  'high.evi.rxn.BS', "u", 2, "numeric", "Reactions with an associated blast-hit with a bitscore above this value will be added to the draft model as core reactions (i.e. high-sequence-evidence reactions)",
  'min.bs.for.core', "l", 2, "numeric", "Reactions with an associated blast-hit with a bitscore below this value will be considered just as reactions that have no blast hit.",
  'output.dir', 'o', 2, "character", "Directory to store results. Default: \".\" (alternatives not yet implemented)",
  'curve.alpha', 'a', 2, "numeric", "Exponent coefficient for transformation of bitscores to reaction weights for gapfilling. (Default: 1 (neg-linear))"
), ncol = 5, byrow = T)

opt <- getopt(spec)

# Help Screen
if ( is.null(opt$blast.res) | is.null(opt$transporter.res) ) {
  cat(getopt(spec, usage=TRUE))
  q(status=1)
}

# Setting defaults if required
if ( is.null(opt$model.name) ) { opt$model.name = NA_character_ }
if ( is.null(opt$output.dir) ) { opt$output.dir = "." }
if ( is.null(opt$high.evi.rxn.BS) ) { opt$high.evi.rxn.BS = 200 }
if ( is.null(opt$min.bs.for.core) ) { opt$min.bs.for.core = 50 }

# Arguments:
blast.res         <- opt$blast.res
transporter.res   <- opt$transporter.res
model.name        <- opt$model.name
output.dir        <- opt$output.dir
high.evi.rxn.BS   <- opt$high.evi.rxn.BS
min.bs.for.core   <- opt$min.bs.for.core
curve.alpha       <- opt$curve.alpha

if(is.na(model.name))
  model.name <- gsub("-all-Reactions.tbl","",basename(blast.res), fixed = T)

# Get Candidate reaction list for gapfilling algorithm
cand.rxn.out <- prepare_candidate_reaction_tables(blast.res = blast.res, transporter.res = transporter.res,
                                                  high.evi.rxn.BS = high.evi.rxn.BS, min.bs.for.core = min.bs.for.core,
                                                  curve.alpha = curve.alpha)

cand.rxn.gf <- cand.rxn.out$dt.cand

saveRDS(cand.rxn.gf,file = paste0(model.name, "-rxnWeights.RDS"))

