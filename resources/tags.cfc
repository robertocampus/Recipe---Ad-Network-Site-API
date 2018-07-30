<cfcomponent extends="taffyAPI.base" taffy_uri="/tags/" hint="Using this user can able to <code>GET</code> and <code>POST</code> tags details">

	<cffunction name="GET" access="public" hint="Return tags cloud Listing DATA using filters and pagination" returntype="struct" output="true">
		<cfargument name="filters" 		type="struct"  required="false" default="#StructNew()#"  hint="Blog Listing Filters struct">
		<cfargument name="pagination"  	type="struct"  required="false" default="#StructNew()#"  hint="Blog Listing Pagination struct">
		<cfargument name="entityID"   	type="numeric" required="false" default="0" >
		<cfargument name="entityTypeID"	type="numeric" required="true">
		<cfargument name="tagName"		type="string"  required="false" default="">
 		<!--- :: init result structure --->	
		<cfset result 	 = StructNew() />
		<cfset local 	 = StructNew() />
		<cfset result['status'] = false />
		<cfset result['message'] = ''>
    
   		<cfparam name="arguments.pagination.orderCol" default="t.tagID">

		<cfscript>
			// check pagination
			// this normalizes the pagination structure (it might be invalid or missing parameters)
			arguments.pagination = checkPagination(arguments.pagination);

		</cfscript>

		<cftry>

			<cfquery datasource="#variables.datasource#" name="result.query">

				SELECT DISTINCT t.tagName
				FROM tags AS t
				
				INNER JOIN tagging AS tg ON tg.tagID = t.tagID

				WHERE  1 = 1
					<cfif arguments.entityID NEQ 0 >
						AND tg.entityID = <cfqueryparam value="#arguments.entityID#" cfsqltype="cf_sql_integer">
					</cfif>
					<cfif arguments.entityTypeID NEQ 0 >
						AND  tg.entityTypeID = <cfqueryparam value="#arguments.entityTypeID#" cfsqltype="cf_sql_integer">
					</cfif>
					<cfif arguments.tagName NEQ "" >
						AND  t.tagName LIKE <cfqueryparam value="#arguments.tagName#%" cfsqltype="cf_sql_varchar" >
					</cfif>

	 			
				ORDER BY #arguments.pagination.orderCol# #arguments.pagination.orderDir# LIMIT #arguments.pagination.offset#, #arguments.pagination.limit# 
				
			</cfquery>		

			
			<cfset local.tt=arraynew(2)>
			
			<!--- // START: Any records? --->
			<cfif result.query.recordCount EQ 0 >
				
				<!--- <cfset local.maximum = result.query.total>
			
				<cfquery name="local.qq" dbtype="query">

					SELECT *, ( (total/#local.maximum#) *100 ) AS p
					FROM result.query
					ORDER BY tagName ASC

				</cfquery>
		
				<cfset local.Tagclass = structNew()>

				<cfloop query="local.qq">

					<cfscript>
						// determine the class for this term based on the percentage
					    if ( p < 5 ) {
					    	class = 'smallest';
					    } else if ( p >= 5 and p < 20 ) {
					        class = 'small';
					    } else if ( p >= 20 and p < 50 ) {
					        class = 'medium';
					    } else if ( p >= 50 and p < 80 ) {
					        class = 'large';
					    } else {
					        class = 'largest';
					    }
				 		structInsert(local.Tagclass, tagName,class);

					</cfscript>

				</cfloop>	
				
				<cfset result.tags = local.Tagclass>

			<cfelse> --->
				<cfset result.message = application.messages['tags_get_found_error']>
				<cfreturn noData().withStatus(404)>

			</cfif>

			<!--- // END: Any records? --->

			 
			<cfcatch>
				<!--- :: degrade gracefully :: --->
				<cfset result.message = errorMessage(message='database_query_error', error = variables.cfcatch)>
				<!--- // 666, 'Database Error', 1 --->
				<cfset logAction( actionID = 666, errorCatch = variables.cfcatch, extra="method:/tags/GET")>	
				<cfreturn representationOf(result.message).withStatus(500)>

	        </cfcatch>
	    </cftry> 

	    <cfset result.message = application.messages['tags_get_found_success']>
		<cfset result.status = true />
		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>	


	<cffunction name="POST" access="public" hint="Insert Tags" returntype="struct" output="true" auth="true">
		<cfargument name="entityID" 	type="numeric"  required="true"	>
		<cfargument name="entityTypeID" type="numeric" 	required="true">	
		<cfargument name="tags"			type="string" 	required="true" 	hint="Tags List">
		<cfargument name="userID"     	type="numeric"	required="true"     hint="userID">
		<cfargument name="auth_token" 	type="string" 	required="true"     hint="auth_token">
	
		<!--- :: init result structure --->	
		<cfset var result 		= StructNew() />
		<cfset var local  		= StructNew() />
		<cfset result['status']  	= false />
		<cfset result['message'] = ''>

		<cftry>

			<cfloop list="#arguments.tags#" index="thisTag">
				
				<cfquery datasource="#variables.datasource#" name="local.getTag"> 

					SELECT tagID 
					FROM tags
					WHERE tagName = '#thisTag#' 
					LIMIT 0,1

				</cfquery>	
				
				<!--- // START: tag already exists? --->
				<cfif local.getTag.recordCount EQ 0>	
					
					<cfquery datasource="#variables.datasource#" name="query" result="qry">

						INSERT INTO tags ( tagName ) 
						VALUES ( '#thisTag#' )
						
					</cfquery>
					
					<cfset local.tagID = qry.GENERATED_KEY>		
				
				<cfelse>
				
					<cfset local.tagID = local.getTag.tagID>	
				
				</cfif>
				<!--- // END: tag already exists? --->
		  	
				<cfquery datasource="#variables.datasource#" name="query"> 

					INSERT INTO tagging ( 
											tagID,
											entityID,
											entityTypeID,
											userID,
											taggingDate 
										)
									VALUES ( 
												<cfqueryparam value="#local.tagID#" cfsqltype="cf_sql_integer">, 
												<cfqueryparam value="#arguments.entityID#" cfsqltype="cf_sql_integer">,
												<cfqueryparam value="#arguments.entityTypeID#" cfsqltype="cf_sql_integer">,
												<cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">,
												<cfqueryparam value="#dateTimeFormat(now(), 'yyyy-mm-dd hh:nn:ss')#" cfsqltype="cf_sql_timestamp">
											)

				</cfquery>
		 		
			</cfloop>	
			
			<cfcatch>
				<cfset result.meassage = errorMessage(message = 'tags_post_add_error', error = variables.cfcatch)>
				<!--- // 91, 'Error: Tags Insert', 'Error encountered while insersting user tags', 1 --->
				<cfset logAction( actionID = 1301,  errorCatch = variables.cfcatch,  extra = "method: /tags/POST")>	
				<cfreturn representationOf(result.message).withStatus(500)>

			</cfcatch> 

		</cftry>
	 	<cfset result.message = application.messages['tags_post_add_success']>
			<!--- // 90, 'Tags Re-Inserted', 'User inserted blog tags.', 1 --->
    	<cfset logAction( actionID = 90,  extra = "method: /tags/POST" )>	
	
		<cfset result.status = true />
		<cfset result.message = "success"/>
   
		<cfreturn representationOf(result).withStatus(200) />

	</cffunction> 

</cfcomponent>