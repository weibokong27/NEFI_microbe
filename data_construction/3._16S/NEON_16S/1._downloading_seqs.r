# Script for downloading raw 16S amplicon sequencing data from NEON

# Dependencies
require(dplyr) # install.packages("dplyr")
require(neonUtilities) # install.packages("neonUtilities")
library(RCurl)

# To download NEON data, we use custom functions that are contais within the following script:
script <- getURL("https://github.com/claraqin/NEON_soil_microbe_processing/blob/master/R/utils.R", ssl.verifypeer = FALSE)
eval(parse(text = script))

# We begin by downloading the metadata associated with the collection and analysis of NEON soil microbial samples, using the `downloadSequenceMetadata()` function. A joined table containing information about the raw data URLs and the marker gene sequencing parameters is returned by this function. 
# 
# If time and space limitations are not issues for you, you can download the entire dataset over the course of a few hours. However, `downloadSequenceMetadata()` accepts arguments that can be used to specify the subset of the data you are interested in keeping for your analysis. We only retain samples from the year 2014.
meta <- downloadSequenceMetadata(startYrMo = "2013-06", endYrMo = "2015-01", 
                                 sites = "all", targetGene = "16S")
# Remove TAR archives generated by later sequencing protocols
meta <- meta[!grepl("archive", meta$rawDataFileDescription),] 

# Download sequence data. This assumes you have specified a download directory using the paths.r file.
download_success <- downloadRawSequenceData(meta, ignore_tar_files = T, outdir = NEON.seq.dir)