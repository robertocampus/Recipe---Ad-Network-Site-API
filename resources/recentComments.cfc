<cfcomponent extends="taffyAPI.base" taffy_uri="/recentComments">

	<cffunction name="GET" access="public" hint="Return Comment Listing DATA using filters and pagination" returntype="struct" output="true">
		<cfargument name="filters" type="struct" default="#StructNew()#" required="no" hint="Blog Listing Filters struct">
		<cfargument name="pagination"  type="struct" default="#StructNew()#" required="no" hint="Blog Listing pagination struct">
		
		<cfparam name="arguments.pagination.orderCol" default="commentID">
		
		<cfscript>
			// check pagination
			// this normalizes the pagination structure (it might be invalid or missing parameters)
			arguments.pagination = checkPagination(arguments.pagination);

		</cfscript>
		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset result['status']  = false />
		<cfset result['message'] = "" />
  
		<cftry>
		
			<cfquery datasource="#variables.datasource#" name="result.query">
	 		SELECT SQL_CALC_FOUND_ROWS
					DISTINCT
					 commentID
					,entityID
					,commentParentID
					,entityTypeID
					,commentIP
					,commentDate
					,commentText
					,commentStatusID
					,comments.active
					
					,comments.userID
					,u.username
					,u.useravatarURL
					
					,CASE comments.entityTypeID
						WHEN 1 THEN lcase(v.itemTypeName)
						WHEN 2 THEN 'images'
						WHEN 3 THEN 'blogs'
						WHEN 4 THEN 'members'
						WHEN 5 THEN 'contest'
					END AS itemTypeName
					
					,CASE comments.entityTypeID
						WHEN 1 THEN i.itemTitle
						WHEN 2 THEN ii.imageID
						WHEN 3 THEN bb.blogTitle
						WHEN 4 THEN u.username
						WHEN 5 THEN c.contestName
					END AS itemTitle
					
					,CASE comments.entityTypeID
						WHEN 1 THEN lcase(i.itemSlug)
						WHEN 2 THEN ii.imageID
						WHEN 3 THEN bb.blogSlug
						WHEN 4 THEN u.username
						WHEN 5 THEN c.contestSlug
					END AS itemSlug
		 			
					,CASE comments.userID
					WHEN 0 THEN commentAuthorName
					ELSE u.userFirstName
					END AS commentAuthorName,
					
					CASE comments.userID
					WHEN 0 THEN commentAuthorEmail
					ELSE u.userEmail
					END AS commentAuthorEmail,
					
					CASE comments.userID
					WHEN 0 THEN commentAuthorURL
					ELSE u.username
					END AS commentAuthorURL
					
					FROM comments
					LEFT JOIN users u ON u.userID = comments.userID
					LEFT JOIN userblogs ub ON u.userID = ub.userID
					LEFT JOIN blogs b on b.blogID = ub.blogID
					LEFT JOIN blogs bb ON bb.blogID = comments.entityID
					LEFT JOIN users uu ON uu.userID = comments.entityID
		      		LEFT JOIN images ii ON ii.imageID = comments.entityID
					LEFT JOIN items i ON i.itemID = comments.entityID
					LEFT JOIN val_itemtype v ON v.itemTypeID = i.itemTypeID
					LEFT JOIN contests c ON c.contestID = comments.entityID AND comments.entityTypeID = 5
	 
				WHERE comments.active = 1
				
				AND commentStatusID = 2
				
	 			ORDER BY #arguments.pagination.orderCol# #arguments.pagination.orderDir# LIMIT #arguments.pagination.offset#, #arguments.pagination.limit#
			</cfquery>
	  		
			<cfquery datasource="#variables.datasource#" name="result.rows">
				SELECT FOUND_ROWS() AS total_count;
			</cfquery>			
			
			
			<cfset result.status  	= true />
			   
	 	    <cfcatch>
				
				<!--- :: degrade gracefully :: --->
				
				<cfset result.message = errorMessage( message = 'database_query_error', error = variables.cfcatch)>
		
				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset logAction( actionID = 661, extra = "method: getComments", errorCatch = variables.cfcatch  )>	
			  	<cfreturn representationOf(result.message).withStatus(500)>

			</cfcatch>
		
	    </cftry> 
	  	
	  	<cfset result.message = application.messages['comment_get_found_success']>
		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>

</cfcomponent>