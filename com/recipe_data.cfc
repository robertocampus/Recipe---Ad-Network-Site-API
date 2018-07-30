<cfcomponent extends="taffyAPI.base" displayname="recipe_data" hint="data from recipes">
	<cfprocessingdirective pageEncoding="utf-8">
	<!--- Query For recipeImportTask Table Start from Here --->

	<!--- :: METHOD: createRecipeImportTask :: --->
	<cffunction name="createRecipeImportTask" access="public" output="true" >
		<cfargument name="source_url" 		type="string" 	required="true" >
		<cfargument name="total_rows" 		type="numeric" 	required="false" default="0">
		<cfargument name="current_row" 		type="numeric" 	required="true">
		<cfargument name="UserID" 			type="numeric" 	required="true">
		<cfargument name="BlogID" 			type="numeric" 	required="false" default="0">
		<cfargument name="isError" 			type="numeric" 	required="false" default="0">
		<cfargument name="isParsed" 		type="numeric" 	required="false" default="0">
		<cfargument name="isCompleted" 		type="numeric" 	required="false" default="0">

		<cfset local.query = "" />

		<cfquery datasource="#variables.datasource#" name="local.query" result="qry">
			INSERT INTO recipes_importtasks (
											source_url,
											total_rows,
											current_row,
											userID,
											blogID,
											importTask_StartDate,
											isError,
											isParsed,
											isCompleted
											)
			VALUES (
					<cfqueryparam value="#arguments.source_url#" cfsqltype="cf_sql_varchar">,
					<cfqueryparam value="#arguments.total_rows#" cfsqltype="cf_sql_integer">,
					<cfqueryparam value="#arguments.current_row#" cfsqltype="cf_sql_integer">,
					<cfqueryparam value="#arguments.UserID#" cfsqltype="cf_sql_integer">,
					<cfqueryparam value="#arguments.BlogID#" cfsqltype="cf_sql_integer">,
					<cfqueryparam value="#datetimeformat(now(), 'yyyy-mm-dd hh:nn:ss')#" cfsqltype="cf_sql_timestamp">, 
					<cfqueryparam value="#arguments.isError#" cfsqltype="cf_sql_tinyint">,
					<cfqueryparam value="#arguments.isParsed#" cfsqltype="cf_sql_tinyint">,
					<cfqueryparam value="#arguments.isCompleted#" cfsqltype="cf_sql_tinyint">
					)
		</cfquery>

		<cfreturn qry.GENERATED_KEY />

	</cffunction>

	<!--- :: METHOD: getRecipesImportTask :: --->
	<cffunction name="getRecipesImportTask" access="public" returntype="Query" >
		<cfargument name="userID" 	 	type="numeric" required="true">
		<cfargument name="isCompleted" 	type="numeric" required="false">		
		<cfargument name="importTaskID" 	type="numeric" required="false">		

		<cfquery datasource="#variables.datasource#" name="local.query">
			
			SELECT importTaskID, total_rows, current_row, source_url
					FROM recipes_importtasks
					WHERE 1 = 1 
					<cfif structKeyExists(arguments, "userID")	AND arguments.userID NEQ ''>
						AND userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_numeric">
					</cfif>
					<cfif structKeyExists(arguments, "isCompleted")	AND arguments.isCompleted NEQ ''>
						AND isCompleted = <cfqueryparam value="#arguments.isCompleted#" cfsqltype="cf_sql_numeric">						
					</cfif>
					<cfif structKeyExists(arguments, "importTaskID")	AND arguments.importTaskID NEQ ''>
						AND importTaskID = <cfqueryparam value="#arguments.importTaskID#" cfsqltype="cf_sql_numeric">
					</cfif>
						AND isParsed = <cfqueryparam value="1" cfsqltype="cf_sql_numeric">
						AND isError  = <cfqueryparam value="0" cfsqltype="cf_sql_numeric">

		</cfquery>

		<cfreturn local.query />
		
	</cffunction>

	<!--- :: METHOD: updateRecipeImportTaskByID :: --->
	<cffunction name="updateRecipeImportTaskByID" access="public" returntype="void" >
		<cfargument name="importTaskID" 	type="numeric" required="true">
		<cfargument name="isError" 			type="numeric" required="false">
		<cfargument name="total_rows" 		type="numeric" required="false">
		<cfargument name="isParsed" 		type="numeric" required="false">

		<cfquery datasource="#variables.datasource#" name="local.query">
			
			UPDATE recipes_importtasks SET 

					isError = <cfqueryparam value="#arguments.isError#" cfsqltype="cf_sql_tinyint">,
					total_rows = <cfqueryparam value="#arguments.total_rows#" cfsqltype="cf_sql_integer">,
					isParsed = <cfqueryparam value="#arguments.isParsed#" cfsqltype="cf_sql_integer">

					WHERE importTaskID = <cfqueryparam value="#arguments.importTaskID#" cfsqltype="cf_sql_numeric">

		</cfquery>
		
	</cffunction>

	<!--- :: METHOD: updateRecipeImportTaskCurrentRow :: --->
	<cffunction name="updateRecipeImportTaskCurrentRow" access="public" returntype="void" >
		<cfargument name="importTaskID" 	type="numeric" required="true">
		<cfargument name="currentRow"		type="numeric" required="false">
		

		<cfquery datasource="#variables.datasource#" name="local.query">
			
			UPDATE recipes_importtasks AS rt
				
				INNER JOIN 	( 

								SELECT current_row + 1 AS currrentRow, importTaskID FROM recipes_importtasks

							) AS rtc ON rtc.importTaskID = rt.importTaskID

					 SET rt.current_row = rtc.currrentRow

					WHERE rt.importTaskID = <cfqueryparam value="#arguments.importTaskID#" cfsqltype="cf_sql_numeric">

		</cfquery>
		
	</cffunction>

	<!--- :: METHOD: completeRecipeImportTask :: --->	
	<cffunction name="completeRecipeImportTask" access="public" returntype="void" >
		<cfargument name="importTaskID" 	type="numeric" required="true">
		<cfargument name="isCompleted"		type="numeric" required="true">
		

		<cfquery datasource="#variables.datasource#" name="local.query">
			UPDATE recipes_importtasks SET 
					isCompleted = <cfqueryparam value="#arguments.isCompleted#" cfsqltype="cf_sql_numeric">
					WHERE importTaskID = <cfqueryparam value="#arguments.importTaskID#" cfsqltype="cf_sql_numeric">
		</cfquery>
		
	</cffunction>

	<!--- Query For recipeImportTask Table Ends Here --->

	<!--- Query For recipeImport Table Start from Here --->


	<!--- :: METHOD: createRecipeImport :: --->
	<cffunction name="createRecipeImport" access="public" returntype="void" >
		<cfargument name="importTaskID" 	type="numeric" 	required="true">
		<cfargument name="source_url" 		type="string" 	required="true" >
		<cfargument name="UserID"			type="numeric"	required="true">
		
		<cfset local.query = "" />

		<cfquery datasource="#variables.datasource#" name="local.query" result="qry">
			INSERT INTO recipes_import (
										importTaskID,
										source_url,
										userID,
										importDate
										)
			VALUES (
					<cfqueryparam value="#arguments.importTaskID#" cfsqltype="cf_sql_tinyint">,
					<cfqueryparam value="#arguments.source_url#"   cfsqltype="cf_sql_varchar">,
					<cfqueryparam value="#arguments.userID#"	   cfsqltype="cf_sql_integer">,
					<cfqueryparam value="#datetimeformat(now(), 'yyyy-mm-dd hh:nn:ss')#"  cfsqltype="cf_sql_timestamp">				
					)
		</cfquery>

	</cffunction>

	<!--- :: METHOD: readRecipeImports :: --->
	<cffunction name="readRecipeImports" access="public" returntype="query" output="true" >
		<cfargument name="importTaskID" type="numeric" required="true">

		<cfset local.query = "">

		<cfquery datasource="#variables.datasource#" name="local.query">
			SELECT 
				importID,
				importTaskID,
				source_url 
				FROM recipes_import 
					WHERE importTaskID = <cfqueryparam value="#arguments.importTaskID#" cfsqltype="cf_sql_tinyint" >
					ORDER BY isParsed DESC
		</cfquery>

		<cfreturn local.query>

	</cffunction>	

	<!--- :: METHOD: insertRecipeImport :: --->
	<cffunction name="insertRecipeImport" access="public" output="true" hint="">
		<cfargument name="source_url" 		type="string" 	required="true" >
		<cfargument name="sourceTypeID"		type="numeric"	required="false" default="0" >
		<cfargument name="image" 			type="string" 	required="false" default="" >
		<cfargument name="author"			type="string"	required="false" default="" >
		<cfargument name="title" 			type="string" 	required="false" default="" >
		<cfargument name="prep_time" 		type="string" 	required="false" default="" >
		<cfargument name="cook_time" 		type="string" 	required="false" default="" >
		<cfargument name="total_time" 		type="string" 	required="false" default="" >
		<cfargument name="total_servings" 	type="string" 	required="false" default="" >
		<cfargument name="cuisine" 			type="string" 	required="false" default="" >
		<cfargument name="ingredients" 		type="string" 	required="false" default="" >
		<cfargument name="instructions" 	type="string" 	required="false" default="" >
		<cfargument name="description" 		type="string" 	required="false" default="" >
		<cfargument name="imageID"			type="numeric"	required="false" default="0" >
		<cfargument name="userID"			type="numeric"	required="false" default="0" >
		<cfargument name="blogID"			type="numeric"	required="false" default="0"  >
		<cfargument name="recipeID"			type="numeric"	required="false" default="0"  >
		<cfargument name="isError" 			type="numeric" 	required="false" default="0" >
		<cfargument name="isParsed" 		type="numeric" 	required="false" default="0" >
		<cfargument name="isValid" 			type="numeric" 	required="false" default="0" >
		<cfargument name="active" 			type="numeric" 	required="false" default="1" >
		
		<cfset local.query = "" />

	    <cfquery datasource="#variables.datasource#" name="local.query" result="qry">
	    	
	    	INSERT INTO recipes_import(
						    			source_url,
						    			sourceTypeID,
						    			image,
						    			author,
						    			title,
						    			prep_time,
						    			cook_time,
						    			total_time,
						    			total_servings,
						    			cuisine,
						    			ingredients,
						    			instructions,
						    			description,
						    			imageID,
						    			userID,
						    			blogID,
						    			recipeID,
						    			importDate,
						    			isError,
						    			isParsed,
						    			isValid,
						    			active
						    		) 
	    	VALUES (
	    			<cfqueryparam  value="#arguments.source_url#" 							cfsqltype="cf_sql_varchar"   >,
	    			<cfqueryparam  value="#arguments.sourceTypeID#" 						cfsqltype="cf_sql_integer"   >,
	    			<cfqueryparam  value="#arguments.image#" 								cfsqltype="cf_sql_varchar"   >,
	    			<cfqueryparam  value="#arguments.author#" 								cfsqltype="cf_sql_varchar"   >,
	    			<cfqueryparam  value="#arguments.title#" 								cfsqltype="cf_sql_varchar"   >,
	    			<cfqueryparam  value="#arguments.prep_time#" 							cfsqltype="cf_sql_varchar"   >,
	    			<cfqueryparam  value="#arguments.cook_time#" 							cfsqltype="cf_sql_varchar"   >,
	    			<cfqueryparam  value="#arguments.total_time#" 							cfsqltype="cf_sql_varchar"   >,
	    			<cfqueryparam  value="#arguments.total_servings#" 						cfsqltype="cf_sql_varchar"   >,
	    			<cfqueryparam  value="#arguments.cuisine#" 								cfsqltype="cf_sql_varchar"   >,
	    			<cfqueryparam  value="#arguments.ingredients#" 							cfsqltype="cf_sql_varchar"   >,
	    			<cfqueryparam  value="#arguments.instructions#" 						cfsqltype="cf_sql_varchar"   >,
	    			<cfqueryparam  value="#arguments.description#" 							cfsqltype="cf_sql_varchar"   >,
	    			<cfqueryparam  value="#arguments.imageID#" 								cfsqltype="cf_sql_integer"   >,
	    			<cfqueryparam  value="#arguments.userID#" 								cfsqltype="cf_sql_integer"   >,
	    			<cfqueryparam  value="#arguments.blogID#" 								cfsqltype="cf_sql_integer"   >,
	    			<cfqueryparam  value="#arguments.recipeID#" 							cfsqltype="cf_sql_integer"   >,
	    			<cfqueryparam  value="#datetimeformat(now(), 'yyyy-mm-dd hh:nn:ss')#" 	cfsqltype="cf_sql_timestamp" >,
	    			<cfqueryparam  value="#arguments.isError#" 								cfsqltype="cf_sql_tinyint"   >,
	    			<cfqueryparam  value="#arguments.isParsed#" 							cfsqltype="cf_sql_tinyint"   >,
	    			<cfqueryparam  value="#arguments.isValid#" 								cfsqltype="cf_sql_tinyint"   >,
	    			<cfqueryparam  value="#arguments.active#" 								cfsqltype="cf_sql_tinyint"   >
	    		)

	    </cfquery>

	    <cfreturn qry.GENERATED_KEY />

	</cffunction>

	<!--- :: METHOD: getImportedRecipe :: --->
	<cffunction name="getImportedRecipe" access="public" returntype="query" output="true">
 		<cfargument name="importID"     type="numeric" required="false">
 		<cfargument name="importTaskID" type="numeric" required="false">
 		<cfargument name="source_url"   type="string"  required="false">
 		<cfargument name="userID" 	    type="numeric" required="false">
 		<cfargument name="isValid" 	    type="numeric" required="false">


		<cfset local.query = ""/>

		 <cfquery datasource="#variables.datasource#" name="local.query" >
	    	SELECT 
	    			ri.importID,
	    			ri.importTaskID,
	    			ri.source_url,
	    			ri.imageID,
	    			ri.recipeID,
	    			ri.author,
	    			ri.title,
	    			ri.prep_time,
	    			ri.cook_time,
	    			ri.total_time,
	    			ri.total_servings,
	    			ri.cuisine,
	    			ri.ingredients,
	    			ri.instructions,
	    			ri.description,
	    			i.imagePath
	    		FROM 
	    			recipes_import ri
	    		LEFT JOIN images i ON i.imageID = ri.imageID 
				WHERE 1=1
				<cfif structKeyExists(arguments, "importTaskID")>
					AND ri.importTaskID = <cfqueryparam value="#arguments.importTaskID#" cfsqltype="cf_sql_varchar">
				</cfif>
				<cfif structKeyExists(arguments, "importID")>
					AND ri.importID = <cfqueryparam value="#arguments.importID#" cfsqltype="cf_sql_varchar">
				</cfif>
				<cfif structKeyExists(arguments, "source_url")>
					AND ri.source_url = <cfqueryparam value="#arguments.source_url#" cfsqltype="cf_sql_varchar">
				</cfif>
				<cfif structKeyExists(arguments, "userID")>
					AND ri.userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">
				</cfif>
				<cfif structKeyExists(arguments, "isValid")>
					AND ri.isValid = <cfqueryparam value="#arguments.isValid#" cfsqltype="cf_sql_integer">
				</cfif>				

	    </cfquery>

	    <cfreturn local.query />

	</cffunction>

	<!--- :: METHOD: updateRecipeImport :: --->
	<cffunction name="updateRecipeImport" access="public" returntype="void" output="true" >
		<cfargument name="source_url" 		type="string" 	required="true" >
		<cfargument name="importTaskID"		type="numeric"	required="true" >
		<cfargument name="importID"			type="numeric"	required="true" >
		<cfargument name="sourceTypeID"		type="numeric"	required="false" default="0" >
		<cfargument name="image" 			type="string" 	required="false" default="" >
		<cfargument name="author"			type="string"	required="false" default="" >
		<cfargument name="title" 			type="string" 	required="false" default="" >
		<cfargument name="prep_time" 		type="string" 	required="false" default="" >
		<cfargument name="cook_time" 		type="string" 	required="false" default="" >
		<cfargument name="total_time" 		type="string" 	required="false" default="" >
		<cfargument name="total_servings" 	type="string" 	required="false" default="" >
		<cfargument name="cuisine" 			type="string" 	required="false" default="" >
		<cfargument name="ingredients" 		type="string" 	required="false" default="" >
		<cfargument name="instructions" 	type="string" 	required="false" default="" >
		<cfargument name="description" 		type="string" 	required="false" default="" >
		<cfargument name="imageID"			type="numeric"	required="false" default="0" >
		<cfargument name="userID"			type="numeric"	required="false" default="0" >
		<cfargument name="blogID"			type="numeric"	required="false" default="0"  >
		<cfargument name="recipeID"			type="numeric"	required="false" default="0"  >
		<cfargument name="isError" 			type="numeric" 	required="false" default="0" >
		<cfargument name="isParsed" 		type="numeric" 	required="false" default="0" >
		<cfargument name="isValid" 			type="numeric" 	required="false" default="0" >
		<cfargument name="active" 			type="numeric" 	required="false" default="1" >

		<cfset local.query = "">

		<cfquery name="local.query" datasource="#variables.datasource#">
		
			UPDATE recipes_import SET
				image 			=   <cfqueryparam value="#arguments.image#" 		cfsqltype="cf_sql_varchar">,
				author 			=   <cfqueryparam value="#arguments.author#" 		cfsqltype="cf_sql_varchar">,
				title 			=   <cfqueryparam value="#arguments.title#" 		cfsqltype="cf_sql_varchar">,
				prep_time 		=   <cfqueryparam value="#arguments.prep_time#" 	cfsqltype="cf_sql_varchar">,
				cook_time 		=   <cfqueryparam value="#arguments.cook_time#" 	cfsqltype="cf_sql_varchar">,
				total_time 		=   <cfqueryparam value="#arguments.total_time#" 	cfsqltype="cf_sql_varchar">,
				total_servings 	=   <cfqueryparam value="#arguments.total_servings#" cfsqltype="cf_sql_varchar">,
				cuisine 		=   <cfqueryparam value="#arguments.cuisine#" 		cfsqltype="cf_sql_varchar">,
				ingredients 	=   <cfqueryparam value="#arguments.ingredients#" 	cfsqltype="cf_sql_varchar">,
				instructions 	=   <cfqueryparam value="#arguments.instructions#" cfsqltype="cf_sql_varchar">,
				description 	=   <cfqueryparam value="#arguments.description#" 	cfsqltype="cf_sql_varchar">,
				imageID 		=   <cfqueryparam value="#arguments.imageID#" 		cfsqltype="cf_sql_integer">,
				userID 			=   <cfqueryparam value="#arguments.userID#" 		cfsqltype="cf_sql_integer">,
				blogID 			=   <cfqueryparam value="#arguments.blogID#" 		cfsqltype="cf_sql_integer" >,				
				isError 		=   <cfqueryparam value="#arguments.isError#" 		cfsqltype="cf_sql_tinyint" >,
				isParsed 		=   <cfqueryparam value="#arguments.isParsed#" 		cfsqltype="cf_sql_tinyint" >,
				isValid			=   <cfqueryparam value="#arguments.isValid#" 		cfsqltype="cf_sql_tinyint" >,
				active 			=   <cfqueryparam value="#arguments.active#" 		cfsqltype="cf_sql_tinyint" >,
				sourceTypeID    =   <cfqueryparam value="#arguments.active#" 		cfsqltype="cf_sql_integer" >
					WHERE importTaskID =   <cfqueryparam value="#arguments.importTaskID#" cfsqltype="cf_sql_integer">
						AND   importID	=   <cfqueryparam value="#arguments.importID#" cfsqltype="cf_sql_integer">
						AND	  source_url =   <cfqueryparam value="#arguments.source_url#" cfsqltype="cf_sql_varchar"> 
		</cfquery>
		<cfreturn />
	</cffunction>

	<!--- :: METHOD: completeRecipeImport :: --->
	<cffunction name="completeRecipeImport" access="public" returntype="void" >
		<cfargument name="importTaskID" 	type="numeric" required="true">
		<cfargument name="importID"			type="numeric" required="false">
		<cfargument name="recipeID"			type="numeric" required="false">
		<cfargument name="isParsed"			type="numeric" required="false">
		

		<cfquery datasource="#variables.datasource#" name="local.query">
			UPDATE recipes_import SET
					<cfif structKeyExists( arguments, "isParsed")>
						isParsed = <cfqueryparam value="#arguments.isParsed#" cfsqltype="cf_sql_integer">
					</cfif> 
					<cfif structKeyExists(arguments, "recipeID")>
						recipeID = <cfqueryparam value="#arguments.recipeID#" cfsqltype="cf_sql_integer">
					</cfif>						
				WHERE importTaskID = <cfqueryparam value="#arguments.importTaskID#" cfsqltype="cf_sql_integer">
					<cfif structKeyExists(arguments, "recipeID")>
						AND importID = <cfqueryparam value="#arguments.importID#" cfsqltype="cf_sql_integer">
					</cfif>
		</cfquery>
		
	</cffunction>

	<!--- Query For recipe_import Table ends Here --->
	

	<!--- Query to insert the image details into images Table start from Here --->

	<!--- :: METHOD: insertImage :: --->
	<cffunction name="insertImage" access="public" output="true" >
		<cfargument name="imageName" 			type="string"	required="true" >
		<cfargument name="imageAlt" 			type="string" 	required="false" default="" >
		<cfargument name="imageFileName" 		type="string"	required="false" default="" >
		<cfargument name="imageFileNameHalf" 	type="string" 	required="false" default="" >
		<cfargument name="imageThumbFileName" 	type="string"	required="false" default="" >
		<cfargument name="imagePath" 			type="string" 	required="false" default="" >
		<cfargument name="active"				type="numeric"	required="false" default="1" >
		<cfargument name="userID"				type="numeric"	required="true" >
		<cfargument name="blogID"				type="numeric"	required="false" default="0" >

		<cfquery name="local.query" datasource="#variables.datasource#" result="qry">
			INSERT INTO images(
								imageName,
								imageAlt,
								imageFileName,
								imageFileNameHalf,
								imageThumbFileName,
								imageCreateDate,
								active,
								imagePath,
								userID,
								blogID
							) 
			VALUES (
					<cfqueryparam cfsqltype="cf_sql_varchar"   value="#arguments.imageName#" >,
					<cfqueryparam cfsqltype="cf_sql_varchar"   value="#arguments.imageAlt#" >,
					<cfqueryparam cfsqltype="cf_sql_varchar"   value="#arguments.imageFileName#" >,
					<cfqueryparam cfsqltype="cf_sql_varchar"   value="#arguments.imageFileNameHalf#" >,
					<cfqueryparam cfsqltype="cf_sql_varchar"   value="#arguments.imageThumbFileName#" >,
					<cfqueryparam cfsqltype="cf_sql_timestamp" value="#datetimeformat(now(), 'yyyy-mm-dd hh:nn:ss')#" >,
					<cfqueryparam cfsqltype="cf_sql_smallint"  value="#arguments.active#" >,
					<cfqueryparam cfsqltype="cf_sql_varchar"   value="#arguments.imagePath#" >,
					<cfqueryparam cfsqltype="cf_sql_integer"   value="#arguments.userID#" >,
					<cfqueryparam cfsqltype="cf_sql_integer"   value="#arguments.blogID#" >
				)
		</cfquery>

		<cfreturn qry.GENERATED_KEY />

	</cffunction>

	<!--- Query to insert the image details into images Table ends Here --->

	<!--- Query for single recipe insert to get lookup tables ID's start from here--->
	
	<!--- :: METHOD: getLineAmountValues :: --->
	<cffunction name="getLineAmountValues" access="public" output="true" returntype="any">
		<cfargument name="amountValue" type="string" required="false" default="0">
		<cfset local.qry = "">

		<cfquery name="local.qry" datasource="#variables.datasource#">
			SELECT amountTypeID FROM val_recipe_amounttype
				WHERE amountTypeName = <cfqueryparam value="#arguments.amountValue#" cfsqltype="cf_sql_varchar">
		</cfquery>

		<cfreturn local.qry.amountTypeID>
	</cffunction>

	<!--- :: METHOD: getunitTypeValues :: --->
	<cffunction name="getunitTypeValues" access="public" output="true" >
		<cfargument name="unitTypeName" type="string" required="false" default="">
		<cfset local.query = "">
		<cfquery name="local.query" datasource="#variables.datasource#">
			SELECT unitTypeID FROM val_recipe_unittype
				WHERE unitTypeDescription = <cfqueryparam value="#arguments.unitTypeName#" cfsqltype="cf_sql_varchar">
					OR unitTypeDescription = <cfqueryparam value="#arguments.unitTypeName#" cfsqltype="cf_sql_varchar">
		</cfquery>
		<cfreturn local.query.unitTypeID>
	</cffunction>
	
	<!--- :: METHOD: isExistingredientID :: --->
	<cffunction name="isExistingredientID" access="public" output="true">
		<cfargument name="ingredientName" type="string" required="false" default="">
		<cfargument name="statusID" type="numeric" required="false" default= "1">
		<!--- <cfargument name="count" type="string" required="false" default=""> --->
 		<cfset local.query = "">

		<cfquery name="getIngredientID" datasource="#variables.datasource#">
			SELECT * from val_recipe_ingredient
			WHERE ingredientName like <cfqueryparam value="%#arguments.ingredientName#%" cfsqltype="cf_sql_varchar">
		</cfquery>

		<cfif getIngredientID.recordcount>
			
			<cfreturn getIngredientID.ingredientID>

		<cfelse>

			<cfquery name="getIngredientID" datasource="#variables.datasource#" result="qry">

				INSERT INTO val_recipe_ingredient (
													ingredientName,
													statusID
												  )
					VALUES (
								<cfqueryparam value="#arguments.ingredientName#" cfsqltype="cf_sql_varchar">,
							
								<cfqueryparam value="#arguments.statusID#" cfsqltype="cf_sql_integer">
						   )
			</cfquery>
			

			<cfreturn qry.GENERATED_KEY>
			
		</cfif>

	</cffunction>

	
	<!--- Query for single recipe insert to get lookup tables ID's ends here--->

	<!--- Query to check the recipe ingredient in USDA table data Starts from here --->

	<!--- :: METHOD: getIngredientValues :: --->
	<cffunction name="getIngredientValues" access="public" output="true" >
		<cfargument name="ingredient" type="string" required="true" default="">
		
		<cfset local.query = "">
		
		<cfquery name="local.query" datasource="#variables.datasource#">
			
			SELECT 	NDB_No, 
					Long_Desc
				FROM usda_food_des 
			WHERE Long_Desc LIKE <cfqueryparam value="#trim(arguments.ingredient)#%" cfsqltype="cf_sql_varchar">

		</cfquery>

		<cfreturn local.query>

	</cffunction>	

	<!--- :: METHOD: getIngredient :: --->
	<cffunction name="getIngredient" access="public" output="true" >
		<cfargument name="ingredientMatchedQuery" type="query" required="true">
		<cfargument name="ingredient" type="string" required="true" default="">

		
		<cfset local.query = "">
		
		<cfquery dbtype="query" name="local.query">
			
			SELECT 	NDB_No, 
					Long_Desc
				FROM arguments.ingredientMatchedQuery 
			WHERE Long_Desc = <cfqueryparam value="#LTrim(arguments.ingredient)#" cfsqltype="cf_sql_varchar">

		</cfquery>

		<cfreturn local.query>

	</cffunction>

	<!--- Query to check the recipe ingredient in USDA table data ends here --->

	<cffunction name="getRecipeDirections" returntype="Query" access="public">
		<cfargument name="directionID" type="string" required="false" default="">
		<cfargument name="recipeID" 	type="string" required="false" default="">

		<cfquery name="local.ingredientDetails" datasource="#variables.datasource#">
			SELECT 	id, 
					imageID, 
					directionText
				FROM recipes_directions
			WHERE 1=1
			<cfif arguments.directionID NEQ '' >
				AND id = <cfqueryparam value="#arguments.directionID#" cfsqltype="cf_sql_varchar" />
			</cfif>
			<cfif arguments.recipeID NEQ '' >
				AND recipeID = <cfqueryparam value="#arguments.recipeID#" cfsqltype="cf_sql_varchar" />
			</cfif>
		</cfquery>

		<cfreturn local.ingredientDetails />

	</cffunction>

	<cffunction name="removeSpecialChars" access="public" output="true">

		<cfargument name="ingredientLine" type="string" required="true">

		<cfscript>

			result = structnew();
			
			local.specialChar = {"½":"1/2","¼":"1/4","¾":"3/4","⅓":"1/3", "⅔":"2/3","⅕":"1/5","⅖":"2/5","⅗":"3/5","⅘":"4/5","⅙":"1/6","⅚":"5/6","⅛":"1/8","⅜":"3/8","⅝":"5/8","⅞":"7/8","1⁄2":"1/2","1⁄4":"1/4","3⁄4":"3/4","1⁄3":"1/3", "2⁄3":"2/3","1⁄5":"1/5","2⁄5":"2/5","3⁄5":"3/5","4⁄5":"4/5","1⁄6":"1/6","5⁄6":"5/6","1⁄8":"1/8","3⁄8":"3/8","5⁄8":"5/8","7⁄8":"7/8","&":"and","´":"'","’":"'","–":"-","⁄":"/"};

			for( key in local.specialChar){

				// if(findNoCase(key, arguments.ingredientLine)){

					arguments.ingredientLine=replaceNoCase(arguments.ingredientLine, key, structFind(local.specialChar,key), "all");
				// }
				
			}
			result.ingredientLine = arguments.ingredientLine;
			return result;	
		</cfscript>

	</cffunction>

</cfcomponent>