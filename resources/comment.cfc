<cfcomponent extends="taffyAPI.base" taffy:uri="/comment/{id}" hint="comment used to get, update and delete user's comments.">

	<cffunction name="GET" access="public" output="false" hint="user used get single comment using commentID by <code>GET</code> Method.">
		<cfargument name="id" type="numeric" required="true" hint="ID should have comment's commentID" />
		
		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset result['status']  = false />
		<cfset result['message'] = "" />

		<cftry>		

			<cfquery datasource="#variables.datasource#" name="result.query" cachedwithin="#CreateTimeSpan(0,0,5,0)#"> 
	 		SELECT
					DISTINCT
					 commentID
					,entityID
					,entityTypeID
					,commentParentID
					,commentIP
					,commentDate
					,commentText
					,commentStatusID
					,comments.active
					
					,comments.userID
					,u.username
					,CONCAT( ui.imagePath, '/', ui.imageName ) AS 'author_FullSize_Image'
					,CONCAT( ui.imagePath, '/', ui.imageThumbFileName ) AS 'author_Thumb_Image'
					,CONCAT( ui.imagePath, '/', ui.imageFileNameHalf ) AS 'author_mini_Image'
					
					,CONCAT( ci.imagePath, '/', ci.imageName ) AS 'comment_FullSize_Image'
					,CONCAT( ci.imagePath, '/', ci.imageThumbFileName ) AS 'comment_Thumb_Image'
					,CONCAT( ci.imagePath, '/', ci.imageFileNameHalf ) AS 'comment_mini_Image'
					
					,CASE comments.entityTypeID
						WHEN 1 THEN 'items'
						WHEN 2 THEN 'images'
						WHEN 3 THEN 'blogs'
						WHEN 4 THEN 'members'
						WHEN 5 THEN 'contest'
						WHEN 10 THEN 'recipes'
					END AS itemTypeName
					
					,CASE comments.entityTypeID
						WHEN 1 THEN i.itemTitle
						WHEN 2 THEN ii.imageID
						WHEN 3 THEN bb.blogTitle
						WHEN 4 THEN u.username
						WHEN 5 THEN c.contestName
						WHEN 10 THEN r.recipeTitle					
					END AS itemTitle
					
					,CASE comments.entityTypeID
						WHEN 1 THEN lcase(i.itemSlug)
						WHEN 2 THEN ii.imageID
						WHEN 3 THEN bb.blogSlug
						WHEN 4 THEN u.username
						WHEN 5 THEN c.contestSlug
						WHEN 10 THEN r.recipeSlug
					END AS itemSlug
		 			
					,CASE comments.userID
					WHEN 0 THEN commentAuthorName
					ELSE u.userFirstName
					END AS commentAuthorName
					
					,CASE comments.userID
					WHEN 0 THEN commentAuthorEmail
					ELSE u.userEmail
					END AS commentAuthorEmail
					
					,CASE comments.userID
					WHEN 0 THEN commentAuthorURL
					ELSE u.username
					END AS commentAuthorURL					

					FROM comments
					LEFT JOIN images ci ON ci.entityID = comments.commentID AND ci.entitytypeID = 6					
					LEFT JOIN users u ON u.userID = comments.userID
					LEFT JOIN images ui ON ui.entityID = u.userID AND ui.entitytypeID = 4
					LEFT JOIN userblogs ub ON u.userID = ub.userID
					LEFT JOIN blogs b on b.blogID = ub.blogID
					LEFT JOIN blogs bb ON bb.blogID = comments.entityID
					LEFT JOIN users uu ON uu.userID = comments.entityID
		      		LEFT JOIN images ii ON ii.imageID = comments.entityID
					LEFT JOIN items i ON i.itemID = comments.entityID
					LEFT JOIN recipes r ON r.recipeID = comments.entityID
					LEFT JOIN val_itemtype v ON v.itemTypeID = i.itemTypeID
					LEFT JOIN contests c ON c.contestID = comments.entityID AND comments.entityTypeID = 5
	 
				WHERE comments.active = 1
				
				AND commentStatusID = 2
				AND commentID = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
			</cfquery>

			<cfif result.query.recordCount EQ 0 >
				<cfset result.message = application.messages['comment_get_found_error']>
				<cfreturn representationOf(result).withStatus(404) />
			</cfif>

			<cfcatch>
				<!--- :: degrade gracefully :: --->
				
				<cfset result.message = errorMessage( message = 'database_query_error', error = variables.cfcatch )>
		
				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset local.logAction = logAction( actionID = 661, extra = "method: /comment/{id}/GET", errorCatch = variables.cfcatch  )>
				
				<cfreturn representationOf(result.message).withStatus(500) />
			</cfcatch>
		
		</cftry>

		<cfset result.status  	= true />
		<cfset result.message 	= application.messages['comment_get_found_success']>

	  	<cfset local.tmp = logAction( actionID = 316, extra = "method: /comment/{id}/GET"  )>
		
		<cfreturn representationOf(result).withStatus(200) />		
	</cffunction>

	<!--- PUT method in this component requires user authentication --->
	<cffunction name="PUT" access="public" output="false" hint="user can update their comments using <code>PUT</code> method." auth="true">
		<cfargument name="commentID" 			required="false"	type="numeric"	/>
		<cfargument name="commentParentID" 		required="false"	type="numeric"	/>
		<cfargument name="entityID" 			required="false"	type="numeric"	/>
		<cfargument name="entityTypeID"			required="false"	type="numeric"	/>
		<cfargument name="commentStatusID" 		required="false"	type="string"	/>
		<cfargument name="userID" 				required="false"	type="numeric"	/>
		<cfargument name="commentAuthorName" 	required="false"	type="string"	/>
		<cfargument name="commentAuthorEmail" 	required="false"	type="string"	/>
		<cfargument name="commentAuthorURL" 	required="false"	type="string" 	/>
		<cfargument name="commentText" 			required="false"	type="string"	/>
		<cfargument name="active" 				required="false"	type="numeric"	/>
		<cfargument name="auth_token" type="string" required="yes" hint="User authorization token (auth_token)">

		<!--- :: init result structure --->
		<cfset var result = StructNew() />
		<cfset result['status']  = false />
		<cfset result['message'] = "" />

		<cftry>
			
			<cfset var local.qry = "" />

			<cfquery name="local.qry" datasource="#variables.datasource#" result="isUpdated">
				UPDATE comments
				SET commentID = commentID
					<cfif structKeyExists(arguments, "userID")>
						,userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_bigint"	/>					
					</cfif>
					<cfif structKeyExists(arguments, "commentText") AND len(arguments.commentText)>
						,commentText = <cfqueryparam value="#arguments.commentText#" cfsqltype="cf_sql_varchar"	/>					
					</cfif>
					<cfif structKeyExists(arguments, "commentAuthorName") AND len( arguments.commentAuthorName )>
						,commentAuthorName = <cfqueryparam value="#arguments.commentAuthorName#" cfsqltype="cf_sql_varchar"	/>					
					</cfif>
					<cfif structKeyExists(arguments, "commentAuthorEmail") AND len( arguments.commentAuthorEmail )>
						,commentAuthorEmail = <cfqueryparam value="#arguments.commentAuthorEmail#" cfsqltype="cf_sql_char"	/>					
					</cfif>
					<cfif structKeyExists(arguments, "entityID")>
						,entityID = <cfqueryparam value="#arguments.entityID#" cfsqltype="cf_sql_bigint"	/>					
					</cfif>
					<cfif structKeyExists(arguments, "commentParentID")>
						,commentParentID = <cfqueryparam value="#arguments.commentParentID#" cfsqltype="cf_sql_bigint" 	/>					
					</cfif>
					<cfif structKeyExists(arguments, "entityTypeID")>
						,entityTypeID = <cfqueryparam value="#arguments.entityTypeID#" cfsqltype="cf_sql_integer"	/>					
					</cfif>

					,commentIP = <cfqueryparam value="#CGI.REMOTE_ADDR#" cfsqltype="cf_sql_varchar"	/>
					,commentDate = <cfqueryparam value="#datetimeFormat(now(), 'yyyy-mm-dd hh:nn:ss')#" cfsqltype="cf_sql_timestamp"	/>
					
					<cfif structKeyExists(arguments, "commentStatusID") AND len(arguments.commentStatusID )>
						,commentStatusID = <cfqueryparam value="#arguments.commentStatusID#" cfsqltype="cf_sql_varchar"	/>
					</cfif>
					<cfif structKeyExists(arguments, "commentAuthorURL") AND len(arguments.commentAuthorURL )>
						,commentAuthorURL = <cfqueryparam value="#arguments.commentAuthorURL#" cfsqltype="cf_sql_varchar"	/>
					</cfif>
					<cfif structKeyExists(arguments, "active")>
						,active = <cfqueryparam value="#arguments.active#" cfsqltype="cf_sql_tinyint"	/>
					</cfif>
					WHERE commentID = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.id#" />
			</cfquery>

			<cfcatch>
				<!--- :: degrade gracefully :: --->
				<cfset result.message = errorMessage(message = 'database_query_error', error = variables.cfcatch)>
		
				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset local.logAction = logAction( actionID = 661, extra = "method: /comment/{id}/PUT", errorCatch = variables.cfcatch )>

				<cfreturn representationOf(result.message).withStatus(500) />
			</cfcatch>

		</cftry>

		<cfset statusCode = ( isUpdated.recordCount GT 0 ) ? 200 : 404 >

		<cfset result.message = "success" />

	  	<cfset local.tmp = logAction( actionID = 1208, extra = "method: /comment/{id}/PUT"  )>

		<cfreturn noData().withStatus(statusCode) />
	</cffunction>	
	
	<cffunction name="DELETE" access="public" output="false" hint="user can delete their comments using <code>DELETE</code> method." auth="true">
		<cfargument name="id" type="numeric" required="yes" hint="ID of commented item" />
		<cfargument name="userID" type="numeric" required="yes" hint="userID">
		<cfargument name="auth_token" type="string" required="yes" hint="User authorization token (auth_token)">

		<!--- :: init result structure --->
		<cfset var result = StructNew() />
		<cfset result['status']  = false />
		<cfset result['message'] = "" />
		
		<cftry>
			<cfset var local.qry = "" />

			<cfquery name="local.qry" datasource="#variables.datasource#" result="isDeleted">
				DELETE FROM comments WHERE commentID = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.id#" />
				LIMIT 1
			</cfquery>

			<cfcatch>
				<!--- :: degrade gracefully :: --->
			
				<cfset result.message = errorMessage( message = 'database_query_error', error = variables.cfcatch )>
		
				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset local.logAction = logAction( actionID = 661, extra = "method: /comment/{id}/DELETE", errorCatch = variables.cfcatch )>

				<cfreturn representationOf(result.message).withStatus(500) />

			</cfcatch>

		</cftry>

		<cfset statusCode = ( isDeleted.recordCount GT 0 ) ? 200 : 404 >

		<cfset result['status']  = true />
		<cfset result.message 	 = "success" />

	  	<cfset local.tmp = logAction( actionID = 314, extra = "method: /comment/{id}/DELETE" )>

		<cfreturn noData().withStatus(statusCode) />
	</cffunction>

</cfcomponent>