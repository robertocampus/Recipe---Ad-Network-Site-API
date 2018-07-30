<cfcomponent extends="taffyAPI.base" taffy_uri="/items" hint="item used to get Items">

	<!--- Method :: GET --->
	<cffunction name="GET" access="public" hint="Return Items Listing DATA using filters and pagination" returntype="struct" output="false">
		<cfargument name="filters" type="struct" default="#StructNew()#" required="no" hint="Blog Listing Filters struct">
		<cfargument name="pagination"  type="struct" default="#StructNew()#" required="no" hint="Blog Listing Pagination struct">
	
		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset result['status']  	= false />
		<cfset result['message'] 	= "" />

		<cfscript>
			// check pagination
			// this normalizes the pagination structure (it might be invalid or missing parameters)
			arguments.pagination = checkPagination(arguments.pagination);
		</cfscript>

		<cftry> 

		    <cfquery datasource="#variables.datasource#" name="result.query"><!---  cachedwithin="#CreateTimeSpan(0,1,0,0)#" --->

			    DROP temporary table if exists _tmp_item_search;
				CREATE temporary TABLE _tmp_item_search  (  `itemID` INT(10) UNSIGNED NOT NULL,  PRIMARY KEY (`itemID`) ) ENGINE=MEMORY;
				
				INSERT INTO _tmp_item_search 
				SELECT itemID
				FROM items i
				LEFT JOIN sponsors s ON i.userID = s.userID
				WHERE  ( 	1 = 1

					<!--- ADD FILTERS TO QUERY  --->
					<cfif StructCount(arguments.filters) GT 0>
						
							<cfloop collection="#arguments.filters#" item="thisFilter">

							<!--- SIMPLE SEARCH on items keywords --->
							<cfif	thisFilter EQ "keywords" AND TRIM(arguments.filters[thisFilter]) NEQ "">
									
								AND ( 
									
										<!--- Search in itemTitle --->
										<cfloop list="#arguments.filters[thisFilter]#" index="thisKeyword">
											
											<cfif listFirst(arguments.filters[thisFilter]) NEQ thisKeyword>
												OR
											</cfif>
											i.itemTitle LIKE <cfqueryparam cfsqltype="cf_sql_string" value="%#thisKeyword#%">
										</cfloop>

										<!--- Search over contestDescription --->
										<cfloop list="#arguments.filters[thisFilter]#" index="thisKeyword">
											OR i.itemExcerpt LIKE <cfqueryparam cfsqltype="cf_sql_string" value="%#thisKeyword#%">
										</cfloop>

										<!--- Search over contestDescription --->
										<cfloop list="#arguments.filters[thisFilter]#" index="thisKeyword">
											OR i.itemText LIKE <cfqueryparam cfsqltype="cf_sql_string" value="%#thisKeyword#%">
										</cfloop>
										
										<!--- Search over sponsorName --->
										<cfloop list="#arguments.filters[thisFilter]#" index="thisKeyword">
											OR i.userID IN ( 
																	SELECT userID FROM users 
																		WHERE userFirstName LIKE <cfqueryparam cfsqltype="cf_sql_string" value="%#thisKeyword#%">	
																			OR userLastName  LIKE <cfqueryparam cfsqltype="cf_sql_string" value="%#thisKeyword#%">
																)
										</cfloop>
									)							
								
							<cfelseif	thisFilter EQ "userID">
								AND i.userID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.filters[thisFilter]#">

							<cfelseif	thisFilter EQ "sponsorID">
								AND s.sponsorID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.filters[thisFilter]#">
								
							<cfelseif	thisFilter EQ "ItemTypeID" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND i.ItemTypeID IN ( <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#" list="yes">)

			 				<cfelseif	thisFilter EQ "SearchUserID" AND TRIM(arguments.filters[thisFilter]) NEQ 0 AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND i.userID IN ( <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#" list="yes">

								<!--- OTHER FLAGS --->
							<cfelseif	 arguments.filters[thisFilter] NEQ 0 AND isNumeric(arguments.filters[thisFilter])>
								AND i.#thisFilter# = #val(arguments.filters[thisFilter])#
							</cfif>
						
						</cfloop>					
								
					</cfif>				
					
				)

				AND i.active = 1
				AND i.itemIsPublished = 1
				AND ( i.itemPublishDate <= now() OR i.itemPublishDate IS null )
				AND ( i.itemExpireDate >= now() OR i.itemExpireDate IS null )			
				GROUP BY itemID
				<cfif len(arguments.pagination.orderCol) GT 0>ORDER BY #arguments.pagination.orderCol# #arguments.pagination.orderDir#</cfif>; 


				SELECT	
					 it.itemID
					,it.itemTitle
					,it.itemText
					,it.itemExcerpt
					,it.itemCreateDate
					,it.itempublishdate
					,it.userID
					,lcase(it.itemSlug) AS itemSlug
					,it.itemUpdateDate
					,it.imageID
				 	,CONCAT( img.imagePath, '/', img.imageName ) AS 'item_fullsize_image'
					,CONCAT( img.imagePath, '/', img.imageThumbFileName ) AS 'item_thumb_image'
					,CONCAT( img.imagePath, '/', img.imageFileNameHalf ) AS 'item_mini_image'
					,lcase(vt.itemTypeName) AS itemTypeName
					,( SELECT count(*) FROM comments AS c 
							WHERE c.entityID = it.itemID 
								AND c.entityTypeID = 1 
								AND c.active = 1 
								AND c.commentStatusID = 2 
					) as 'CommentCount'
					,u.userFirstName
					,u.userLastName
					,u.username

					,e.count AS 'popularity'
			
					FROM items it
					INNER JOIN ( SELECT itemID FROM _tmp_item_search ) t ON t.itemID = it.itemID
					LEFT JOIN val_itemtype vt 	 ON vt.ItemTypeID 	= it.itemTypeID
					LEFT JOIN images img		 ON img.entityID 	= it.itemID AND img.entityTypeID = 1
					LEFT JOIN users u			 ON u.userID 		= it.userID
					
					LEFT JOIN entityViewsCount e ON e.entityID 	= it.itemID AND e.entityTypeID = 1

					WHERE it.active = 1	

					limit #arguments.pagination.offset#, #arguments.pagination.limit#;
				
			</cfquery>

			<cfquery datasource="#variables.datasource#" name="local.rows">
				
				SELECT i.itemID
				FROM items i
				LEFT JOIN sponsors s ON i.userID = s.userID
				WHERE  ( 	1 = 1

					<!--- ADD FILTERS TO QUERY  --->
					<cfif StructCount(arguments.filters) GT 0>
						
							<cfloop collection="#arguments.filters#" item="thisFilter">

							<!--- SIMPLE SEARCH on items keywords --->
							<cfif	thisFilter EQ "keywords" AND TRIM(arguments.filters[thisFilter]) NEQ "">
									
								AND ( 
									
										<!--- Search in itemTitle --->
										<cfloop list="#arguments.filters[thisFilter]#" index="thisKeyword">
											
											<cfif listFirst(arguments.filters[thisFilter]) NEQ thisKeyword>
												OR
											</cfif>
											i.itemTitle LIKE <cfqueryparam cfsqltype="cf_sql_string" value="%#thisKeyword#%">
										</cfloop>

										<!--- Search over contestDescription --->
										<cfloop list="#arguments.filters[thisFilter]#" index="thisKeyword">
											OR i.itemExcerpt LIKE <cfqueryparam cfsqltype="cf_sql_string" value="%#thisKeyword#%">
										</cfloop>

										<!--- Search over contestDescription --->
										<cfloop list="#arguments.filters[thisFilter]#" index="thisKeyword">
											OR i.itemText LIKE <cfqueryparam cfsqltype="cf_sql_string" value="%#thisKeyword#%">
										</cfloop>
										
										<!--- Search over sponsorName --->
										<cfloop list="#arguments.filters[thisFilter]#" index="thisKeyword">
											OR i.userID IN ( 
																	SELECT userID FROM users 
																		WHERE userFirstName LIKE <cfqueryparam cfsqltype="cf_sql_string" value="%#thisKeyword#%">	
																			OR userLastName  LIKE <cfqueryparam cfsqltype="cf_sql_string" value="%#thisKeyword#%">
																)
										</cfloop>
									)							
								
							<cfelseif	thisFilter EQ "userID">
								AND i.userID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.filters[thisFilter]#">

							<cfelseif	thisFilter EQ "sponsorID">
								AND s.sponsorID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.filters[thisFilter]#">
								
							<cfelseif	thisFilter EQ "ItemTypeID" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND i.ItemTypeID IN ( <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#" list="yes">)

			 				<cfelseif	thisFilter EQ "SearchUserID" AND TRIM(arguments.filters[thisFilter]) NEQ 0 AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND i.userID IN ( <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#" list="yes">

								<!--- OTHER FLAGS --->
							<cfelseif	 arguments.filters[thisFilter] NEQ 0 AND isNumeric(arguments.filters[thisFilter])>
								AND i.#thisFilter# = #val(arguments.filters[thisFilter])#
							</cfif>
						
						</cfloop>					
								
					</cfif>				
					
				)

				AND i.active = 1
				AND i.itemIsPublished = 1
				AND ( i.itemPublishDate <= now() OR i.itemPublishDate IS null )
				AND ( i.itemExpireDate >= now() OR i.itemExpireDate IS null )			
				GROUP BY itemID;
			</cfquery>

			<cfset result.rows.total_count = local.rows.recordcount >
			
		    <cfcatch>		

				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset logAction( actionID = 661, extra = "method: /items/GET", errorCatch = variables.cfcatch )>
				<cfset result.message =errorMessage( message = 'items_get_found_error', error = variables.cfcatch)>
				<cfreturn representationOf(result.message).withStatus(500) />

		  	</cfcatch>
	
  		</cftry>   

		<cfset result.status  	= true />
		<cfset result.message = application.messages['items_get_found_success'] />

	  	<cfset logAction( actionID = 1015, extra = "method: /items/GET" )>

		<cfreturn representationOf(result).withStatus(200) />
		
	</cffunction>


	<!--- Method :: POST --->
	<cffunction name="POST" access="public" output="false" hint="can create items DATA using <code>POST</code>">
		<cfargument name="itemTitle"        required="true"   type="string"  default="" />
		<cfargument name="itemSlug"         required="false"  type="string"  default="" />
		<cfargument name="itemExcerpt"      required="false"  type="string"  default="" />
		<cfargument name="itemText"         required="false"  type="string"  default="" />
		<cfargument name="itemTypeID"       required="false"  type="numeric" default="0"  />
		<cfargument name="imageID"          required="false"  type="numeric" default="0"  />
		<cfargument name="userID"           required="false"  type="numeric" default="0"  />
		<!---
		<cfargument name="itemCreateDate"   required="false"  type="any"     default=""  />
		--->
		<cfargument name="itemIsPublished"  required="false"  type="numeric" default="0"  />
		<cfargument name="itemIsFeatured"   required="false"  type="numeric" default="0"  />
		<cfargument name="itemPublishDate"  required="false"  type="any"     default=""  />
		<cfargument name="itemExpireDate"   required="false"  type="any"     default=""  />
		<cfargument name="isAllowComment"   required="false"  type="numeric" default="1"  />
		<cfargument name="isCustomURL"      required="false"  type="numeric" default="0"  />
		<cfargument name="itemCustomURL"    required="false"  type="string"  default=""  />
		<cfargument name="active"           required="false"  type="numeric" default="1"  />
		<cfargument name="notViewedOnly"    required="false"  type="string"  default=""  />

		<cfset result['message'] = ''>
		<cfset result['status']  = ''>
		<cfset result['error']   =''>

		<cftry>
			
			<cfquery name="local.query" datasource="#variables.datasource#" result="qry">
				INSERT INTO items (
					itemTitle
					,itemSlug
					,itemExcerpt
					,itemText
					,itemTypeID
					,imageID
					,userID
					,itemCreateDate				
					,itemIsPublished
					,itemIsFeatured
					,itemPublishDate
					,itemExpireDate
					,isAllowComment
					,isCustomURL
					,itemCustomURL
					,active
					,notViewedOnly
				)
				VALUES (
					<cfqueryparam value="#arguments.itemTitle#"        cfsqltype="cf_sql_varchar"     />
					,<cfqueryparam value="#arguments.itemSlug#"         cfsqltype="cf_sql_varchar"    />
					,<cfqueryparam value="#arguments.itemExcerpt#"      cfsqltype="cf_sql_varchar"    />
					,<cfqueryparam value="#arguments.itemText#"         cfsqltype="cf_sql_varchar"    />
					,<cfqueryparam value="#arguments.itemTypeID#"       cfsqltype="cf_sql_integer"    />
					,<cfqueryparam value="#arguments.imageID#"          cfsqltype="cf_sql_integer"    />
					,<cfqueryparam value="#arguments.userID#"           cfsqltype="cf_sql_integer"    />
					,<cfqueryparam value="#datetimeFormat(now(), 'yyyy-mm-dd hh:nn:ss')#" cfsqltype="cf_sql_timestamp"  />
					,<cfqueryparam value="#arguments.itemIsPublished#"  cfsqltype="cf_sql_tinyint"    />
					,<cfqueryparam value="#arguments.itemIsFeatured#"   cfsqltype="cf_sql_tinyint"    />
					,<cfqueryparam value="#arguments.itemPublishDate#"  cfsqltype="cf_sql_timestamp"  />
					,<cfqueryparam value="#arguments.itemExpireDate#"   cfsqltype="cf_sql_timestamp"  />
					,<cfqueryparam value="#arguments.isAllowComment#"   cfsqltype="cf_sql_tinyint"    />
					,<cfqueryparam value="#arguments.isCustomURL#"      cfsqltype="cf_sql_tinyint"    />
					,<cfqueryparam value="#arguments.itemCustomURL#"    cfsqltype="cf_sql_varchar"    />
					,<cfqueryparam value="#arguments.active#"           cfsqltype="cf_sql_tinyint"    />
					,<cfqueryparam value="#arguments.notViewedOnly#"    cfsqltype="cf_sql_bit"        />
				)
			</cfquery>

			<cfquery name="result.query" datasource="#variables.datasource#">
				SELECT * FROM items
				WHERE itemID = <cfqueryparam value="#qry.GENERATED_KEY#" cfsqltype="cf_sql_integer">
			</cfquery>

			<cfcatch>

				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset logAction( actionID = 661, extra = "method: /items/POST", errorCatch = variables.cfcatch )>
				<cfset result.message = errorMessage( message = 'items_post_add_error', error = variables.cfcatch)>
				<cfreturn representationOf(result.message).withStatus(500) />

			</cfcatch>
		
		</cftry>
			 
		<cfset result.status  	= true />
		<cfset result.message = application.messages['items_post_add_success']>

	  	<cfset logAction( actionID = 1001, extra = "method: /items/POST" )>

		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>

</cfcomponent>