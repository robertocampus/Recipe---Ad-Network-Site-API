<cfcomponent extends="taffyAPI.base" taffy:uri="/comments" hint="comment used to get comments">

	<cffunction name="GET" access="public" hint="Return Comment Listing DATA using filters and pagination" returntype="struct" output="true">
		<cfargument name="filters" type="struct" default="#StructNew()#" required="no" hint="Blog Listing Filters struct">
		<cfargument name="pagination"  type="struct" default="#StructNew()#" required="no" hint="Blog Listing pagination struct">
		
		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset result['status']  = false />
		<cfset result['message'] = "" />

		<cftry>
			
			<cfscript>
				// check pagination
				// this normalizes the pagination structure (it might be invalid or missing parameters)
				arguments.pagination = checkPagination(arguments.pagination);
			</cfscript>
	  		
			<cfquery datasource="#variables.datasource#" name="result.query"><!---  cachedwithin="#CreateTimeSpan(0,1,0,0)#" --->

				DROP temporary table if exists _tmp_comment_search;
				CREATE temporary TABLE _tmp_comment_search  ( `commentID` INT(10) UNSIGNED NOT NULL,  PRIMARY KEY (`commentID`) ) ENGINE=MEMORY;
				
				INSERT INTO _tmp_comment_search 
				SELECT commentID
				FROM comments
				WHERE  ( 	1 = 1

					<!--- ADD FILTERS TO QUERY  --->
					<cfif StructCount(arguments.filters) GT 0>
						
		  				<cfloop collection="#arguments.filters#" item="thisFilter">
						 
							<!--- SIMPLE SEARCH on Item Title --->	
							<cfif thisFilter EQ "SearchText" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND commentText LIKE '%#arguments.filters[thisFilter]#%'
							
							<cfelseif thisFilter EQ "entityTypeID" AND TRIM(arguments.filters[thisFilter]) NEQ "" >
								AND entityTypeID = #val(arguments.filters[thisFilter])#
							<cfelseif thisFilter EQ "entityID" AND TRIM(arguments.filters[thisFilter]) NEQ "" >
								AND entityID = #val(arguments.filters[thisFilter])#
							<cfelseif thisFilter EQ "commentParentID" AND TRIM(arguments.filters[thisFilter]) NEQ "" >
								AND commentParentID = #val(arguments.filters[thisFilter])#
		 					<!--- OTHER FLAGS --->
							<cfelseif arguments.filters[thisFilter] NEQ 0 AND isNumeric(arguments.filters[thisFilter])>
								AND comments.#thisFilter# = #val(arguments.filters[thisFilter])#
							</cfif>
						
						</cfloop>					
								
					</cfif>
				)
				AND active = 1
				GROUP BY commentID
				<cfif len(arguments.pagination.orderCol) GT 0>ORDER BY #arguments.pagination.orderCol# #arguments.pagination.orderDir#</cfif>; 

	 			SELECT 
	 				 c.commentID
					,c.entityID
					,c.commentParentID
					,c.entityTypeID
					,c.commentIP
					,c.commentDate
					,c.commentText
					,c.commentStatusID
					,c.active
					<!--- ,lcase(i.itemSlug) AS itemSlug --->
					,lcase(ve.entityTypeName) AS entityTypeName
					,c.userID
					,u.username
					,CONCAT( ui.imagePath, '/', ui.imageName ) AS 'author_FullSize_Image'
					,CONCAT( ui.imagePath, '/', ui.imageThumbFileName ) AS 'author_Thumb_Image'
					,CONCAT( ui.imagePath, '/', ui.imageFileNameHalf ) AS 'author_mini_Image'

					,CONCAT( ci.imagePath, '/', ci.imageName ) AS 'comment_FullSize_Image'
					,CONCAT( ci.imagePath, '/', ci.imageThumbFileName ) AS 'comment_Thumb_Image'
					,CONCAT( ci.imagePath, '/', ci.imageFileNameHalf ) AS 'comment_mini_Image'
					
					,CASE c.userID
					WHEN 0 THEN commentAuthorName
					ELSE u.userFirstName
					END AS commentAuthorName,
					
					CASE c.userID
					WHEN 0 THEN commentAuthorEmail
					ELSE u.userEmail
					END AS commentAuthorEmail,
					
					CASE c.userID
					WHEN 0 THEN commentAuthorURL
					ELSE u.username
					END AS commentAuthorURL
					
					FROM comments c
					INNER JOIN ( SELECT commentID FROM _tmp_comment_search limit #arguments.pagination.offset#, #arguments.pagination.limit# ) t ON t.commentID = c.commentID
					LEFT JOIN images ci ON ci.entityID = c.commentID AND ci.entitytypeID = 6					
					LEFT JOIN users u ON u.userID = c.userID
					LEFT JOIN images ui ON ui.entityID = u.userID AND ui.entitytypeID = 4								
					LEFT JOIN val_entityType ve ON ve.entityTypeID = c.entityTypeID					
	 
				WHERE c.active = 1
				
			</cfquery>

			<cfquery datasource="#variables.datasource#" name="local.rows">
				SELECT commentID
				FROM comments
				WHERE  ( 	1 = 1

					<!--- ADD FILTERS TO QUERY  --->
					<cfif StructCount(arguments.filters) GT 0>
						
		  				<cfloop collection="#arguments.filters#" item="thisFilter">
						 
							<!--- SIMPLE SEARCH on Item Title --->	
							<cfif thisFilter EQ "SearchText" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND commentText LIKE '%#arguments.filters[thisFilter]#%'
							
							<cfelseif thisFilter EQ "entityTypeID" AND TRIM(arguments.filters[thisFilter]) NEQ "" >
								AND entityTypeID = #val(arguments.filters[thisFilter])#
							<cfelseif thisFilter EQ "entityID" AND TRIM(arguments.filters[thisFilter]) NEQ "" >
								AND entityID = #val(arguments.filters[thisFilter])#
							<cfelseif thisFilter EQ "commentParentID" AND TRIM(arguments.filters[thisFilter]) NEQ "" >
								AND commentParentID = #val(arguments.filters[thisFilter])#
		 					<!--- OTHER FLAGS --->
							<cfelseif arguments.filters[thisFilter] NEQ 0 AND isNumeric(arguments.filters[thisFilter])>
								AND comments.#thisFilter# = #val(arguments.filters[thisFilter])#
							</cfif>
						
						</cfloop>					
								
					</cfif>
				)
				AND active = 1
				GROUP BY commentID;
			</cfquery>

			<cfset result.rows.total_count = local.rows.recordCount >

			<cfcatch>

				<!--- 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset logAction( actionID = 661, extra = "method: /comments/GET", errorCatch = variables.cfcatch )>
				<cfset result.message 	   = errorMessage(message = 'database_query_error', error = variables.cfcatch ) />
				
				<cfreturn representationOf( result.message ).withStatus(500) />

			</cfcatch>
		
		</cftry>
		
		<cfset result.status  	= true />
		<cfset result.message = "success" />

	  	<cfset logAction( actionID = 316, extra = "method: /comments/GET" )>
		
		<cfreturn representationOf(result).withStatus(200) />
	</cffunction>


	<cffunction name="POST" access="public" output="false" hint="comment create by user or author using <code>POST</code>" auth="true">
		<cfargument name="userID" 				required="yes"		type="numeric" 		hint="userID" />
		<cfargument name="entityTypeID" 		required="yes" 		type="numeric" 		hint="ID of entity type. ie. 10 = recipe; 1 = blog; etc." />
		<cfargument name="entityID" 			required="yes" 		type="numeric" 		hint="ID of entity's item." />
		<cfargument name="commentText" 			required="yes"		type="string" 		hint="comment for the entity's item." />
		<cfargument name="commentParentID" 		required="no"		type="numeric"		default="0" />
		<cfargument name="commentAuthorURL" 	required="no"		type="string" 		default=""	/>
		<cfargument name="active" 				required="no"		type="numeric"		default="1"	/>
		<cfargument name="imageID" 				required="no"		type="numeric"		default="0"	/>
		<cfargument name="auth_token" 			required="yes"		type="string" 		hint="User authorization token (auth_token)" />
		

		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset result['status']  = false />
		<cfset result['message'] = "" />

		<cftry>

			<cfquery name="local.entityTypeQuery" datasource="#variables.datasource#" >
				SELECT entityTable FROM val_entityType
					WHERE entityTypeID = <cfqueryparam value="#arguments.entityTypeID#" cfsqltype="cf_sql_integer" >
			</cfquery>

			<cfif local.entityTypeQuery.recordCount >

				<cfset pkStruct = {"items":"itemID", "images":"imageID", "blogs":"blogID", "users":"userID", "contests":"contestID", "recipes":"recipeID", "sponsors":"sponsorID"}>
				
				<cfif structKeyExists( pkStruct, local.entityTypeQuery.entityTable )>
					
					<cfquery name="local.entityItemQuery" datasource="#variables.datasource#" >
						SELECT * FROM #local.entityTypeQuery.entityTable#
							WHERE #pkStruct[local.entityTypeQuery.entityTable]# = <cfqueryparam value="#arguments.entityID#" cfsqltype="cf_sql_integer" >
					</cfquery>

				<cfelse>

					<!--- Oh..! seems the entity Type you commented was not valid. --->
					<cfset result.message 	= application.messages['comments_post_added_error'] />
					<cfreturn representationOf(result).withStatus(404) />

				</cfif>
				
				<cfif local.entityItemQuery.recordCount >

					<cfquery name="local.query" datasource="#variables.datasource#" result="qry">
						INSERT INTO comments (												
												 commentParentID
												,commentIP
												,commentDate												
												,userID
												,commentText
												,commentAuthorName
												,commentAuthorEmail
												,commentAuthorURL
												,active
												,entityTypeID
												,entityID
											)
								SELECT 	 <cfqueryparam value="#arguments.commentParentID#"		cfsqltype="cf_sql_bigint" 	/>
										,<cfqueryparam value="#CGI.REMOTE_ADDR#"				cfsqltype="cf_sql_varchar"	/>
										,<cfqueryparam value="#datetimeFormat(now(), 'yyyy-mm-dd hh:nn:ss')#" cfsqltype="cf_sql_timestamp"	/>										
										,<cfqueryparam value="#arguments.userID#"				cfsqltype="cf_sql_bigint"	/>
										,<cfqueryparam value="#arguments.commentText#"			cfsqltype="cf_sql_varchar"	/>
										,userName AS commentAuthorName
										,userEmail AS commentAuthorEmail
										,<cfqueryparam value="#arguments.commentAuthorURL#"		cfsqltype="cf_sql_varchar"	/>
										,<cfqueryparam value="#arguments.active#"				cfsqltype="cf_sql_tinyint"	/>
										,<cfqueryparam value="#arguments.entityTypeID#"			cfsqltype="cf_sql_integer"	/>
										,<cfqueryparam value="#arguments.entityID#"				cfsqltype="cf_sql_integer"	/>
									 FROM users WHERE userID = <cfqueryparam value="#arguments.userID#"	cfsqltype="cf_sql_bigint"	/>
					</cfquery>
					
					<cfset local.commentID = qry.GENERATED_KEY >
					
					<!--- START: Calling images endpoint to upload the comment post image into Amazon S3 --->					
					<cfif arguments.imageID NEQ 0 >
						
						<cfset local.attributes.entityID 	= local.commentID />					
						<cfset local.attributes.entityTypeName = 'comment' />					

						<cfset local.imageResponse = httpRequest( methodName = 'PUT', endPointOfURL = '/image/#arguments.imageID#', timeout = 3000, parameters = local.attributes ) />

					</cfif>
					<!--- END: Calling images endpoint to upload the image into Amazon S3 --->

				<cfelse>
					
					<!--- Oh..! seems the POST you commented was not valid. --->
					<cfset result.message 	= application.messages['comments_post_added_error'] />
					<cfreturn representationOf(result).withStatus(404) />

				</cfif>

			<cfelse>

				<!--- Oh..! seems the entity you commented was not valid. --->
				<cfset result.message 	= application.messages['comments_post_added_error'] />
				<cfreturn representationOf(result).withStatus(404) />

			</cfif>

			<cfcatch>
				<cfset logAction( actionID = 661, extra = "method: /comments/POST", errorCatch = variables.cfcatch ) >
				<cfset result.message 	   = errorMessage(message = 'database_query_error', error = variables.cfcatch ) />
				
				<cfreturn representationOf( result.message ).withStatus(500) />
			</cfcatch>
		
		</cftry>
			 
		<cfset result.status  	= true />				
		<cfset result.message 	= application.messages['comments_post_added_success'] />
		
	  	<cfset logAction( actionID = 310, extra = "method: /comments/POST" )>

		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>

</cfcomponent>