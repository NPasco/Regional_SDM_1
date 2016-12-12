# File: 5_createMetadata.r
# Purpose: to summarize validation data and other information about the 
# model and write it to a pdf. This pdf should accompany ALL sharing/showing
# of the SDM map.

# For knitr to work, you need MikTex installed. See http://miktex.org/

# load libraries ----
library(ROCR)  #July 2010: order matters, see http://finzi.psych.upenn.edu/Rhelp10/2009-February/189936.html
library(randomForest)
library(knitr)
library(raster)
library(maptools)
library(sp)
library(rgdal)
library(RColorBrewer)
library(rgdal)
library(rasterVis)
library(RSQLite)
library(xtable)

inPath <- "K:/Reg5Modeling_Project/outputs"

## find and load model data ----
# get a list of what's in the directory

d <- dir(path = inPath, pattern = ".Rdata",full.names=FALSE)
d
# which one do we want to run?
n <- 3
fileName <- d[[n]]
load(paste(inPath,fileName, sep="/"))

## set paths (after loading Rdata file in case objects exist) ----
rnwPath <- "K:/Reg5Modeling_Project/scripts/Regional_SDM"
outPath <- "K:/Reg5Modeling_Project/outputs/metadata"
gridpath <- "K:/Reg5Modeling_Project/outputs/grids"
stateBoundPath <- "K:/Reg5Modeling_Project/other_spatial"
dbLoc <- "K:/Reg5Modeling_Project/databases"

extentMapName <- "StateBoundariesAlbersConicEqualArea"

testareapath <- "K:/Reg5Modeling_Project/other_spatial"
testAreaName <- "reg5_pred_20161027"

ras <- raster(paste(gridpath, "/", ElementNames$Code, ".tif", sep = ""))


## Get Program and Data Sources info ----

db_file <- paste(dbLoc, "SDM_lookupAndTracking.sqlite", sep = "/")
db <- dbConnect(SQLite(),dbname=db_file)  
SQLquery <- paste("Select lkpModelers.ProgramName, lkpModelers.FullOrganizationName, ",
  "lkpModelers.City, lkpModelers.State, lkpSpecies.CODE ",
  "FROM lkpModelers ", 
  "INNER JOIN lkpSpecies ON lkpModelers.ModelerID=lkpSpecies.ModelerID ", 
  "WHERE lkpSpecies.CODE='", ElementNames$Code, "'; ", sep="")
sdm.modeler <- dbGetQuery(db, statement = SQLquery)

SQLquery <- paste("SELECT sp.CODE, sr.ProgramName, sr.State ",
  "FROM lkpSpecies as sp ",
  "INNER JOIN mapDataSourcesToSpp as mp ON mp.EstID=sp.EST_ID ",
  "INNER JOIN lkpDataSources as sr ON mp.DataSourcesID=sr.DataSourcesID ",
  "WHERE sp.CODE='", ElementNames$Code, "'; ", sep="")
sdm.dataSources <- dbGetQuery(db, statement = SQLquery)
sdm.dataSources <- sdm.dataSources[order(sdm.dataSources$ProgramName),]

SQLquery <- paste("SELECT ID, date, speciesCode, comments",
                  " FROM tblCustomModelComments ", 
                  "WHERE speciesCode='", ElementNames$Code, "'; ", sep="")
sdm.customComments <- dbGetQuery(db, statement = SQLquery)
# assume you want the most recently entered comments, if there are multiple entries
if(nrow(sdm.customComments) > 1) {
  rowToGet <- nrow(sdm.customComments)
  sdm.customComments <- sdm.customComments[order(sdm.customComments$date),]
  sdm.customComments.subset <- sdm.customComments[rowToGet,]
} else {
  sdm.customComments.subset <- sdm.customComments
}

## Run knitr and create metadata ----

# writing to the same folder as a grid might cause problems.
# if errors check that first
#   more explanation: tex looks for and uses aux files, which are also used
#   by esri. If there's a non-tex aux file, knitr bails. 

# Also, might need to run this twice. First time through tex builds the reference
# list, second time through it can then number the refs in the doc.

setwd(outPath)

knit2pdf(paste(rnwPath,"MetadataEval_knitr.rnw",sep="/"), output=paste(ElementNames$Code, ".tex",sep=""))

## clean up ----
dbDisconnect(db)
# remove all objects before moving on to the next script
rm(list=ls())
