<cfcomponent extends="taffyAPI.base" displayname="data" hint="data from val tables">

	<!--- :: METHOD: getResources :: --->
	<cffunction name="getResources" access="public" returntype="struct" hint="Retrieve value tables records and passes them as query in struct">
		<!--- <cfargument name = "mode" type = "string" required = "no" default = "0" hint = "mode"> --->

		<!--- // init result structure --->	
		<cfset var result 		= structNew() />

	 	<cfset local.valueTablesList = "val_entityType,val_action,val_language,val_countries,val_states,val_category,val_location,val_messagetype,val_reportlogtype,val_role,val_source,val_status,val_statuschecktype,val_contestwinnerstatus,val_commentstatus,val_commenttype,val_type,val_subtype,val_publisherstatus,val_publishercompanytype,val_timezone,val_contestregion,val_contestdeclinereason,val_contestactivitytype,val_leadinterested,val_leadtimeframe,val_sponsorcategory,val_sponsorindustry,val_leadentitytype,val_programsitestatus,val_supporttype,val_supportsubtype,val_recipe_amounttype,val_recipe_unittype">

	 	<cfloop list="#local.valueTablesList#" index="thisTable">
	 	
	 		<cfquery name="result.valueTables.#thisTable#" datasource="#variables.datasource#">
	 			SELECT * FROM #thisTable# 
		 			WHERE active = 1
		 			<cfif thisTable EQ "val_countries">
		 				ORDER BY countryFullName ASC
		 			</cfif>
	 		</cfquery>
	 		
	 	</cfloop>

	 	<!--- <cfset result.messages = getmessages() />
	 	<cfset result.types    = valueList(local.valueTables.val_type.typeSlug) & "," & valueList(local.valueTables.val_subType.subTypeSlug)> --->
	 	<cfreturn result />
	</cffunction>


	<!--- :: METHOD: getMessages :: --->
	<cffunction name = "getmessages" access = "public" hint = "Get Messages Data">
		<cfargument name = "action"  type = "string" required = "no" default = "" hint = "null">

		<!--- :: init result structure --->	
		<cfset var result 			= structNew() />
		<cfset var local  			= structNew() />
		<cfset var result.status 	= "false" />
		<cfset var result.message 	= "" /> 

		<cfquery datasource="#variables.datasource#" name="local.query" cachedwithin="#CreateTimeSpan(0,0,1,0)#">
			SELECT messageTextID,messageText	
			FROM messages
				WHERE active = 1
		</cfquery>

		<cfset result.message = queryToStruct(local.query,'messageTextID','messageText')>
		
		<cfreturn result.message />
	</cffunction>		

	<cffunction name="getImageDetails" access="public" hint="Used to get the related image details" returntype="query">
		<cfargument name="entityTypeID"		type="numeric"  required="true"  hint="It represents what type of entity it is. For example, blog or recipe .. etc., " >
		<cfargument name="entityID"			type="numeric"  required="true"  hint="entityID is represents the particular ID of a blog, recipe or user .. etc.," >
		<cfargument name="imageID"			type="numeric"  required="false" hint="imageID used to get the particular image.">		
  			
  
			<cfquery datasource="#variables.datasource#" name="local.query" result="qry">
				SELECT 	imageID,
						imageName,
						entityID,
						entityTypeID
					FROM 
						images 
					WHERE 
							entityID 	 = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.entityID#" />
						AND entityTypeID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.entityTypeID#" />
						<cfif structKeyExists(arguments, "imageID") AND arguments.imageID NEQ 0 >
							AND imageID	 = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.imageID#" />
						</cfif>
			</cfquery>
   		
		<cfreturn  local.query/>

	</cffunction>
	

	<cffunction name="uploadToS3" access="public" hint="Upload File to Amazon S3 bucket" returntype="struct" output="true">
		<cfargument name="fileName"				type="string" 	required="true" hint="File name">
		<cfargument name="localPath"			type="string" 	required="true" hint="Full local path to file">
		<cfargument name="bucketName"			type="string" 	required="true" hint="S3 Bucket Name">
		<cfargument name="subfolderName"		type="string" 	required="true" hint="S3 Bucket file separation context folder Name.">
		  	
		<!--- :: init result structure --->	
		<cfset var result		= StructNew() />
		<cfset var local		= StructNew() />
		<cfset result.status	= false />
 		
 		<cftry>

			<!--- ADDING VALIDATION HERE --->			
			<!--- FILE found? --->

			<cfif NOT FileExists(arguments.localPath&'/'&arguments.fileName) OR len(trim(arguments.bucketName)) EQ 0 >
				
				<cfset result.status = false />

			<cfelse>

				<cfset local.keyName = arguments.subfolderName&'/'&arguments.fileName>

				<!--- Upload File to S3 --->
				<cfset local.uploadFile = application.s3Obj.putObject(bucketName = arguments.bucketName, uploadDir = arguments.localPath&'/', fileKey = arguments.fileName, keyName = local.keyName, contentType = "multipart/form-data", HTTPtimeout = 300)>
				
				<!--- // 3011, 'S3: Upload', 'File uploaded to Amazon S3 Bucket successfully.', 1 --->
				<cfset logAction( actionID = 3011, extra = "AmazonS3 Method: uploadToS3 successfully.")>

				<cfset result.status = true />

			</cfif>				
			
			<cfcatch>
				<cfset logAction( actionID = 3012, errorCatch = variables.cfcatch )>	
			</cfcatch>

		</cftry>
   		
		<cfreturn  result/>

	</cffunction>

	<!--- :: METHOD: checkUserBlogs :: --->
	<cffunction name="checkUserBlogs" access="public" hint="Return user blogs IDs" returntype="struct" output="false">
		<cfargument name="userID" type="string" required="yes" hint="User ID">
		<cfargument name="blogID" type="string" required="yes" hint="Blog ID">
		
		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset result.status  	= false />
		<cfset result.message 	= "" />

		<cftry>
 		
		<cfquery datasource="#variables.datasource#" name="local.query"> 
			SELECT blogID 
			FROM userblogs
			WHERE userID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">	
				AND blogID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.blogID#">
		</cfquery>
		
		<!--- // Found? --->
		<cfif local.query.recordCount GT 0>
			<cfset result.status = true />
		</cfif>				
	   
		<cfcatch>
		
			<!--- :: degrade gracefully :: --->
			<cfset result.query.recordCount = 0>
			<cfset result.message = 999>

			<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
			<cfset logAction( actionID = 661, extra = "method: checkUserBlogs", errorCatch = variables.cfcatch  )>	
 		  
		</cfcatch>
		
	  </cftry>

		<cfreturn result />
	</cffunction>

	<cffunction name="insertTAL" access="public" hint="Insert TAL File Record" returntype="struct" output="true">
		<cfargument name="fileName"				type="string" 	required="yes" 				hint="Image Name">
		<cfargument name="isPending"			type="string" 	required="no"  default="1" 	hint="Is Pending Flag">
		<cfargument name="isApproved"			type="string" 	required="no"  default="0" 	hint="Is Approved Flag">
		<cfargument name="isRejected"			type="string" 	required="no"  default="0" 	hint="Is Rejected Flag">
		<cfargument name="rejectReasonID"		type="string" 	required="no"  default="0" 	hint="Reject Reason ID">
		<cfargument name="blogID"	  			type="string" 	required="no"  default="0"  hint="Blog ID">
		<cfargument name="user"					type="string" 	required="yes" 				hint="User Structure">
		<cfargument name="CGI" 					type="struct"  	required="no"  default="#StructNew()#" hint="CGI VARS structure">
  	
		<!--- :: init result structure --->	
		<cfset var result		= StructNew() />
		<cfset var local		= StructNew() />
		<cfset result.status	= false />
  
		<!---<cftry>--->
  		
			<cfset local.timeStamp = "#DateFormat(now(), "YYYY-MM-DD")# #TimeFormat(now(), " HH:MM:SS")#">
	  	    
			<cfquery datasource="#variables.datasource#" name="local.query">
			INSERT INTO tals 
						( 
							fileName,
							isPending,
							isApproved,
							isRejected,
							rejectReasonID,
							userID,
							blogID,
							createDate,
							active
						)
			VALUES   (
						 <cfqueryparam cfsqltype="cf_sql_varchar" 	value="#left(arguments.fileName, 255)#" maxlength="255">,
						 <cfqueryparam cfsqltype="cf_sql_integer" 	value="#isPending#">,
						 <cfqueryparam cfsqltype="cf_sql_integer" 	value="#isApproved#">,
						 <cfqueryparam cfsqltype="cf_sql_integer" 	value="#isRejected#">,
						 <cfqueryparam cfsqltype="cf_sql_integer" 	value="#rejectReasonID#">,
						 <cfqueryparam cfsqltype="cf_sql_integer"  value="#arguments.user#">,
						 <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.blogID#">,
						 '#local.timeStamp#',
						 1
					)
			</cfquery>		
			
			<cfquery datasource="#variables.datasource#" name="local.getLast"> 
				SELECT LAST_INSERT_ID() AS ID
			</cfquery>
	
			<!--- // 1520	TAL: Inserted	TAL file record inserted successfully.	1 --->
			<cfset local.logAction = logAction( actionID = 1520,  extra = "#local.getLast.ID#", cgi = arguments.cgi )>	
			<cfset result.talID = local.getLast.ID />	
			<cfset result.status = true />
   		
<!--- 		<cfcatch> 
			
			<!--- // 1521	TAL: Insert Error	Error encountered while inserting TAL file record.	1 --->
			<cfset local.logAction = application.dataObj.logAction( actionID = 1521, user = arguments.user, extra = "", errorCatch = variables.cfcatch, cgi = arguments.cgi )>	
				
		</cfcatch> 
		</cftry>--->
       
		<cfreturn result />

	</cffunction>

	<cffunction name="getfbPageID" returntype="Query" access="public" hint="used to get the pageID from the blogs table">
		<cfargument name="blogID" type="numeric" required="true">

		<cfset local.query = "" />

		<cfquery datasource="#variables.datasource#" name="local.query">
            SELECT facebookPageID FROM blogs 
                WHERE blogID = <cfqueryparam value="#arguments.blogID#" cfsqltype="cf_sql_numeric">
        </cfquery>

        <cfreturn local.query />

	</cffunction>

</cfcomponent> 