#Fit dirlichet models to functional groups of fungi from Tedersoo et al. Temperate Latitude Fungi.
#No hierarchy required, as everything is observed at the site level. Each observation is a unique site.
#Missing data are allowed.
#clear environment
rm(list = ls())
library(data.table)
library(doParallel)
source('paths.r')
source('NEFI_functions/ddirch_site.level_JAGS.r')
source('NEFI_functions/crib_fun.r')

#detect and register cores.
n.cores <- detectCores()
registerDoParallel(cores=n.cores)

#load tedersoo data.
d <- data.table(readRDS(ted.ITSprior_data))
start <- which(colnames(d)=="Russula"   )
  end <- which(colnames(d)=="Tricholoma")
y <- d[,start:end]
x <- d[,.(cn,pH,moisture,NPP,map,mat,forest,conifer,relEM)]
d <- cbind(y,x)
d <- d[complete.cases(d),] #optional. This works with missing data.
#d <- d[1:35,] #for testing

#organize y data
start <- which(colnames(d)=="Russula"   )
  end <- which(colnames(d)=="Tricholoma")
y <- d[,start:end]
x <- d[,(end+1):ncol(d)]

#make other column
y <- data.frame(lapply(y,crib_fun))
other <- 1 - rowSums(y)
y <- cbind(other,y)

#Drop in intercept, setup predictor matrix.
intercept <- rep(1, nrow(x))
x <- cbind(intercept, x)

#log transform map, magnitudes in 100s-1000s break this.
x$map <- log(x$map)

#define multiple subsets
x.clim <- x[,.(intercept,NPP,mat,map)]
x.site <- x[,.(intercept,cn,pH,moisture,forest,conifer,relEM)]
x.all  <- x[,.(intercept,cn,pH,moisture,NPP,mat,map,forest,conifer,relEM)]
x.list <- list(x.clim,x.site,x.all)

#fit model using function.
#This take a long time to run, probably because there is so much going on.
#fit <- site.level_dirlichet_jags(y=y,x_mu=x,adapt = 50, burnin = 50, sample = 100)
#for running production fit on remote.
output.list<-
  foreach(i = length(x.list)) %dopar% {
    fit <- site.level_dirlichet_jags(y=y,x_mu=x.list[i],adapt = 200, burnin = 1000, sample = 1000, parallel = T)
    return(fit)
  }
names(output.list) <- c('climate.preds','site.preds','all.preds')

#fit <- site.level_dirlichet_jags(y=y,x_mu=x.all,adapt = 200, burnin = 1000, sample = 1000, parallel = T)

cat('Saving fit...\n')
saveRDS(output.list, ted_ITS.prior_20gen_JAGSfit)
cat('Script complete. \n')

#visualize fits
#par(mfrow = c(1,ncol(fit$observed)))
#for(i in 1:ncol(fit$observed)){
#  plot(fit$observed[,i] ~ fit$predicted[,i], ylim = c(0,1))
#  rsq <- summary(betareg::betareg(fit$observed[,i] ~ fit$predicted[,i]))$pseudo.r.squared
#  txt <- paste0('R2 = ',round(rsq,2))
#  mtext(colnames(fit$predicted)[i], line = -1.5, adj = 0.05)
#  mtext(txt, line = -3.5, adj = 0.05)
#  abline(0,1, lwd = 2)
#  abline(lm(fit$observed[,i] ~ fit$predicted[,i]), lty = 2, col = 'green')
#}
