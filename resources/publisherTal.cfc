<cfcomponent extends="taffyAPI.base" taffy:uri="/publisherTal/" hint="Publisher Meta Data. ie. AdUnits, etc.">

	<cffunction name="GET" access="public" hint="Return Publisher TAL DATA" returntype="struct" output="true">
		<cfargument name="userID"  		type="string"  required="true" hint="User ID">
		<cfargument name="blogID"  		type="string"  required="false"  hint="Blog ID">
		<cfargument name="talID"  		type="string"  required="false"  hint="Tal ID">
		<cfargument name="isApproved"  	type="string"  required="false"  hint="isApproved Flag">
		<cfargument name="isError"  	type="string"  required="false"  hint="isError Flag">
		
		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset var local = StructNew() />
		
		<cfset result['status'] = false />
		<cfset result['message'] = ''>
		
		<cftry>
		
			<cfquery datasource="#variables.datasource#" name="local.query">
				SELECT *
				FROM tals t
				LEFT JOIN val_talrejectedreason vr ON vr.id = t.rejectReasonID			 
				WHERE 1 = 1 
				AND t.userID IN ( <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#"> )
				
				<cfif isDefined("arguments.blogID")>
					AND t.blogID IN ( <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.blogID#"> )
				</cfif>
				
				<cfif isDefined("arguments.talID")>
					AND t.talID IN ( <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.talID#"> )
				</cfif>
				
				<cfif isDefined("arguments.isApproved")>
					AND t.isApproved IN ( <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.isApproved#"> )
				</cfif>
				
				<cfif isDefined("arguments.isError")>
					AND t.isError IN ( <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.isError#"> )
				</cfif>
				 
				ORDER BY t.talID ASC
			</cfquery>
			
			<cfif NOT local.query.recordCount >

				<cfset result.message = ['publisherTal_get_found_error']>
				<cfset  logAction( actionID = 661, extra = "method: getPublicUsers", errorCatch = variables.cfcatch  )>	
				<cfreturn representationOf(result).withStatus(404)>

			</cfif>

			<cfset result.query = local.query>
			
		<cfcatch>
			
			<!--- :: degrade gracefully :: --->
			<cfset result.message = errorMessage(message = 'database_query_error', error = variables.cfcatch)>
	
			<!--- // 1522, error while Getting publisherTal records --->
			<cfset  logAction( actionID = 1522, extra = "method: getPublicUsers", errorCatch = variables.cfcatch  )>	
		  	<cfreturn representationOf(result.message).withStatus(500)>
		</cfcatch>
		
	   </cftry>

	   	<!--- 1523:publisherTal records were got --->
	
		<cfset result.status = true>
		<cfset result.message = application.messages['publisherTal_get_found_success']>
		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>


	<cffunction name="POST" access="public" hint="Insert TAL File Record" returntype="struct" output="true">
		<cfargument name="fileName"				type="string" 	required="true" 				hint="Image Name">
		<cfargument name="isPending"			type="string" 	required="false"  default="1" 	hint="Is Pending Flag">
		<cfargument name="isApproved"			type="string" 	required="false"  default="0" 	hint="Is Approved Flag">
		<cfargument name="isRejected"			type="string" 	required="false"  default="0" 	hint="Is Rejected Flag">
		<cfargument name="rejectReasonID"		type="string" 	required="false"  default="0" 	hint="Reject Reason ID">
		<cfargument name="blogID"	  			type="string" 	required="false"  default="0"  hint="Blog ID">
		<cfargument name="userID"				type="numeric" 	required="true" 				hint="UserID">
  	
		<!--- :: init result structure --->	
		<cfset var result		= StructNew() />
		<cfset var local		= StructNew() />
		<cfset result['status']	= false />
		<cfset result['message'] = ''>
  
		<cftry>
  		
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
						<cfqueryparam cfsqltype="cf_sql_integer"	value="#arguments.userID#">,
						<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.blogID#">,
						 '#local.timeStamp#',
						 1
					)
			</cfquery>		
			
			<cfquery datasource="#variables.datasource#" name="local.getLast"> 
				SELECT LAST_INSERT_ID() AS ID
			</cfquery>
	
			<!--- // 1520	TAL: Inserted	TAL file record inserted successfully.	1 --->
			<cfset logAction( actionID = 1520, extra = "#local.getLast.ID#", cgi = arguments.cgi )>	
			<cfset result.talID = local.getLast.ID />	
   		
	 		<cfcatch> 

				<cfset result.message =errorMesage(message = 'publisherTal_post_add_error', error = variables.cfcatch)>
				<!--- // 1521	TAL: Insert Error	Error encountered while inserting TAL file record.	1 --->
				<cfset logAction( actionID = 1521, user = arguments.user, extra = "", errorCatch = variables.cfcatch, cgi = arguments.cgi )>	
				<cfreturn representationOf(result.message).withStatus(500) />
			</cfcatch> 

		</cftry>

		<cfset result.status = true>
        <cfset result.message = application.messages['publisherTal_post_add_success']>
		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>

</cfcomponent>