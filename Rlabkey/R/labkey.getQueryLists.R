##
#  Copyright (c) 2010-2014 LabKey Corporation
# 
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
##

## public function getQueries, returns all queries associated with a specified schema
labkey.getQueries <- function(baseUrl=NULL, folderPath, schemaName)
{	
	baseUrl=labkey.getBaseUrl(baseUrl)
    mydata <- getQueryLists(baseUrl=baseUrl, folderPath=folderPath, schemaName=schemaName)
	return(mydata)
}

## public function getQueryViews, returns all views associated with a specified query
labkey.getQueryViews <- function(baseUrl=NULL, folderPath, schemaName, queryName)
{
	if(is.null(queryName)==FALSE) {char <- nchar(queryName); if(char<1){queryName<-NULL}}
	if(exists("queryName")==FALSE)  { stop ("You must provide the query on which the view is based.") }

	mydata <- getQueryLists(baseUrl=baseUrl, folderPath=folderPath, schemaName=schemaName, queryName=queryName)
	return(mydata)
}

getQueryLists <- function(baseUrl=NULL, folderPath, schemaName, queryName=NULL)
{
    baseUrl=labkey.getBaseUrl(baseUrl)
    if((length(queryName)>0) && (queryName==curlUnescape(queryName)) ) { queryName <- curlEscape(queryName) }
	## Error if any of baseUrl, folderPath, or schemName are missing
	if(exists("baseUrl")==FALSE || is.null(baseUrl) || exists("folderPath")==FALSE || exists("schemaName")==FALSE )
	    {stop ("A value must be specified for each of baseUrl, folderPath, schemaName.")}

	## URL encoding of schemaName and folderPath (if not already encoded)
	if(schemaName==curlUnescape(schemaName)) {schemaName <- curlEscape(schemaName)}
	if(folderPath==URLdecode(folderPath)) {folderPath <- URLencode(folderPath)}

	## Formatting
	baseUrl <- gsub("[\\]", "/", baseUrl)
	folderPath <- gsub("[\\]", "/", folderPath)
	if(substr(baseUrl, nchar(baseUrl), nchar(baseUrl))!="/"){baseUrl <- paste(baseUrl,"/",sep="" )}
	if(substr(folderPath, nchar(folderPath), nchar(folderPath))!="/"){folderPath <- paste(folderPath,"/",sep="")}
	if(substr(folderPath, 1, 1)!="/"){folderPath <- paste("/",folderPath,sep="")}

	## now setup the different columns for views vs queries
	if(length(queryName)==0)
	{
		serverAction <- "getQueries.view?schemaName="
		qParam <- ""
		queryObjType <- "queries"
		columnNames <- c("queryName", "fieldName")
	}
	else
	{
		serverAction <- "getQueryViews.api?schemaName="  
		qParam <- paste("&queryName=",queryName, sep="")
		queryObjType <- "views"
		columnNames <- c("viewName", "fieldName")
	}

	## Construct url
	myurl <- paste(baseUrl, "query", folderPath, serverAction, schemaName, qParam, "&apiVersion=8.3", sep="")

	## Execute via our standard GET function
	mydata <- labkey.get(myurl);

	decode <- fromJSON(mydata)
	qs <- decode[[queryObjType]]

	dmall <- matrix(nrow=0, ncol=2, byrow=TRUE)

	if (length(qs)>0)
	{
		for (j in 1:length(qs))
		{
			dmq <- matrix(nrow=0, ncol=2, byrow=TRUE)
			nc <- length(qs[[j]]$columns)
				##special handling of the default view
				objName <- qs[[j]][["name"]]
				if (is.null(objName)) 
				{
					objName<- "<default view>"
				}

			for (k in 1:nc) 
			{
				dmqrow<- matrix( cbind(objName, qs[[j]]$columns[[k]]$name),nrow=1, ncol=2, byrow=FALSE)
				dmq<-rbind(dmq, dmqrow)
			}
			dmall <- rbind(dmall,dmq)
		}
	}	
	dfall <- as.data.frame(dmall, stringsAsFactors=FALSE)
	colnames(dfall)<- columnNames

	return(dfall)
}

