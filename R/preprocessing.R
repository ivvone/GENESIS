#' Illustration of preprocessing()
#'
#' This function allows to preprocess the summary-level GWAS statistics. 
#' @param summarydata summay-level GWAS data, containing 3 columns: 
#' SNP (SNP rsID), 
#' Z (GWAS test z-statistic), 
#' N (GWAS study sample size which can be different for different SNPs)
#' @param LDfile filename of LDscore file, used instead of specifying LDcutoff and LDwindow 
#' @param LDcutoff a number from (0.05, 0.1, 0.2); indicating LD score is calculated based on the particular r^2 cutoff. By default, it is 0.1.
#' @param LDwindow a number from (0.5, 1, 2); indicating LD score is calculated based on the particular window size (MB). By default, it is 1 MB.
#' @param filter logical; if TRUE, the input summary data will be filtered.
#' @keywords 
#' @export
#' @examples preprocessing(summarydata, LDcutoff=0.1,LDwindow=1,filter=FALSE)

preprocessing <- function(summarydata, LDfile=NULL, 
                          LDcutoff=0.1,LDwindow=1,filter=FALSE){
  #----------------------------------------------------#----------------------------------------------------
  # I. summary GWAS data format check
  #----------------------------------------------------#----------------------------------------------------
  origFormat = (ncol(summarydata)==3)
  if(ncol(summarydata)!=4 & !origFormat){
    stop("The summary GWAS data should have 4 columns with (SNP rsID, SNP position, Z-statistic, Sample size),
         or 3 columns with (SNP rsID, Z-statistic, Sample size)!")
  }
  
  #----------------------------------------------------#----------------------------------------------------
  # II. preliminary summary GWAS data filtering
  #----------------------------------------------------#----------------------------------------------------
  if(origFormat){
    colnames(summarydata) <- c("SNP", "Z","N")
  } else{
    colnames(summarydata) <- c("SNP", "posSNP", "Z","N")
  }
  
  if(filter==TRUE){
    #a. If sample size varies from SNP to SNP, remove SNPs with an effective sample size less than 0.67 times the 90th percentile of sample size.
    ikeep1 <- which(as.numeric(as.character(summarydata$N))>=0.67*quantile(as.numeric(as.character(summarydata$N)), 0.9))
    summarydata <- summarydata[ikeep1,]
    
    #b. Remove SNPs within the major histocompatibility complex (MHR) region; filter SNPs to Hapmap3 SNPs.
    data(w_hm3.noMHC.snplist)
    ikeep2 <- which(as.character(summarydata$SNP) %in% w_hm3.noMHC.snplist$SNP)
    summarydata <- summarydata[ikeep2,]
    
    #c. Remove SNPs with extremely large effect sizes (chi^2 > 80).
    ikeep3 <- which(as.numeric(as.character(summarydata$Z))^2 <=80)
    summarydata <- summarydata[ikeep3,]
  }
  
  #----------------------------------------------------#----------------------------------------------------
  # III. merge the summary GWAS data with the LD score data
  #----------------------------------------------------#----------------------------------------------------
  if(is.null(LDfile)){
    data(list=paste0("EUR_LDwindow",LDwindow,"MB_cutoff",LDcutoff))
  } else{
    load(LDfile)
  }
  #data(list=paste0("LDwindow",LDwindow,"MB_cutoff",LDcutoff))
  #load(paste0(ancestry,"_LDwindow1MB_cutoff0.1"))
  
  if(origFormat){
    summarydata$SNP <- as.character(summarydata$SNP)
  } else{
    summarydata$SNP <- as.character(summarydata$posSNP)
  }
  
  summarydata$Z <- as.numeric(as.character(summarydata$Z))
  summarydata$N <- as.numeric(as.character(summarydata$N))
  
  # remove NA values.
  inx <- which(is.na(summarydata$Z))
  if(length(inx)>1) summarydata <- summarydata[-inx,]
  inx <- which(is.na(summarydata$N))
  if(length(inx)>1) summarydata <- summarydata[-inx,]
  
  # get the variable needed for our method.
  summarydata$betahat <- summarydata$Z/sqrt(summarydata$N)
  summarydata$varbetahat <- 1/summarydata$N
  df <- merge(summarydata, dataLD,by.x="SNP",by.y="SNPname",sort=F)
  
  return(df)
}


