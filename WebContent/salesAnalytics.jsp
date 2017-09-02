<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="ucsd.shoppingApp.models.* , java.util.*" %>
<%@page import="java.sql.Connection, ucsd.shoppingApp.ConnectionManager, ucsd.shoppingApp.*"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
	<title>Sales Analytics</title>
</head>
<body>	
	<h1>Sales Analytics</h1>
	<%@ page import="java.sql.*"%>
	<%@ page import="java.util.List" %>
	<%@ page import="java.util.ArrayList" %>
<%

	if(session.getAttribute("roleName") != null) {
		 String role = session.getAttribute("roleName").toString();
		if("owner".equalsIgnoreCase(role) == true){ 
			
			
			/* Initialize and prep variables */
			Connection conn = null;
			
			long program_start = System.nanoTime();
			long query_start = 0;
			long query_end = 0;
			long row_query_start = 0;
			long row_query_end = 0;
			long filter_query_start = 0;
			long filter_query_end = 0;
			long category_query_start = 0;
			long category_query_end = 0;
			
			Statement stmt; 
			Statement row_stmt;
			Statement filter_stmt; 
			Statement category_stmt; 
			
			ResultSet rs = null;
			ResultSet row_rs = null;
			ResultSet filter_rs = null;
			ResultSet category_rs = null;
			
			String query = null;			
			String row_query = null;
			String filter_query = null;
			String category_query = "SELECT * FROM Category";
			
			/* Connect to the database */
			try {
				Class.forName("org.postgresql.Driver");
			} catch (Exception e){
				System.out.println("Driver error");
			}
		    conn = DriverManager.getConnection("jdbc:postgresql://localhost/shoppingAppDB?" +"user=postgres&password=postgres");
			
			
		    /* Create the statements to be used */
		    stmt = conn.createStatement();
			category_stmt = conn.createStatement();
			row_stmt = conn.createStatement(ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_UPDATABLE);
			filter_stmt = conn.createStatement(ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_UPDATABLE);
			
			
			/* Grab the option parameters for later use */
			String disabled = "";
	 		String row_menu = "" + request.getParameter("row_menu");
			if(row_menu.equals("") || row_menu.equals("null") || row_menu == null){
				row_menu = "Customers";
			}
			String col_menu = "" + request.getParameter("col_menu");
			String filter = "" + request.getParameter("filter"); 	
			String row_offset = "" + request.getParameter("row_offset");
			String col_offset = "" + request.getParameter("col_offset");

			/* Determine whether or not the buttons should be disabled */
		 	if(!row_offset.equals("0") && row_offset != null && !row_offset.equals("null"))
			{
				disabled = "disabled";
							
			}
			else{
				row_offset = "0";
			}
		 	if(!col_offset.equals("0") && col_offset != null && !col_offset.equals("null"))
			{
				disabled = "disabled";
						
			}
			else{
				col_offset = "0";
			}
		 	
			/* Prepare the queries */
			
			/****************** All categories (default) ******************/
			if(filter == null || filter.equals("All Categories") || filter.equals("null") || filter.equals("all")) {

				/****************** Customers ******************/
				if(row_menu.equals("Customers") || row_menu.equals("null") || row_menu == null){
					/* Alphabetical order */
					if(col_menu.equals("Alphabetical") || col_menu.equals("null") || col_menu == null){	
						row_query = "WITH sales AS (SELECT per.id AS temp_id, person_name AS name, SUM(quantity*pic.price) as total "
								+ "FROM shopping_cart sc, products_in_cart pic, person per, product p "
								+ "WHERE per.id = sc.person_id "
								+ "AND sc.id = pic.cart_id "
								+ "AND sc.is_purchased = TRUE " 
								+ "AND p.id = pic.product_id "
								+ "GROUP BY per.id) "
							+ "SELECT person_name AS name, per.id, COALESCE(sales.total, 0) AS total "
							+ "FROM person per "
							+ "LEFT JOIN sales ON per.id = sales.temp_id "
							+ "ORDER BY name ASC OFFSET " + row_offset + "";
						
						filter_query = "WITH filter_table AS (SELECT p.id AS filter_id, product_name, SUM(quantity*pic.price) AS total "
								+ "FROM product p, products_in_cart pic "
								+ "WHERE p.id = pic.product_id "
								+ "GROUP BY p.id) "
							+ "SELECT p.product_name, p.id, COALESCE(filter_table.total, 0) AS total "
							+ "FROM product p "
                        	+ "LEFT JOIN filter_table ON p.id = filter_table.filter_id "
                        	+ "ORDER BY p.product_name ASC OFFSET " + col_offset + "";
						
					}
					
					/****************** Top-K order by total sales ******************/
					else{
						row_query = "WITH sales AS (SELECT per.id AS temp_id, person_name AS name, SUM(quantity*pic.price) as total "
								+ "FROM shopping_cart sc, products_in_cart pic, person per, product p "
								+ "WHERE per.id = sc.person_id "
								+ "AND sc.id = pic.cart_id "
								+ "AND sc.is_purchased = TRUE " 
								+ "AND p.id = pic.product_id "
								+ "GROUP BY per.id) "
							+ "SELECT person_name AS name, per.id, COALESCE(sales.total, 0) AS total "
							+ "FROM person per "
							+ "LEFT JOIN sales ON per.id = sales.temp_id "
							+ "ORDER BY total DESC OFFSET " + row_offset + "";
						
						filter_query = "WITH filter_table AS (SELECT p.id AS filter_id, product_name, SUM(quantity*pic.price) AS total "
								+ "FROM product p, products_in_cart pic "
								+ "WHERE p.id = pic.product_id "
								+ "GROUP BY p.id) "
							+ "SELECT p.product_name, p.id, COALESCE(filter_table.total, 0) AS total "
							+ "FROM product p "
                        	+ "LEFT JOIN filter_table ON p.id = filter_table.filter_id "
                        	+ "ORDER BY total DESC OFFSET " + col_offset + "";
									
					}
				}
				
				/****************** States ******************/
				else{
					
					/****************** Alphabetical order ******************/
					if(col_menu.equals("Alphabetical") || col_menu.equals("null") || col_menu == null){		
						filter_query = "WITH filter_table AS (SELECT p.id AS filter_id, product_name, SUM(quantity*pic.price) AS total "
								+ "FROM product p, products_in_cart pic "
								+ "WHERE p.id = pic.product_id "
								+ "GROUP BY p.id) "
							+ "SELECT p.product_name, p.id, COALESCE(filter_table.total, 0) AS total "
							+ "FROM product p "
                        	+ "LEFT JOIN filter_table ON p.id = filter_table.filter_id "
                        	+ "ORDER BY p.product_name ASC OFFSET " + col_offset + "";
								
						row_query = "WITH sales AS (SELECT s.id AS temp_id, state_name AS name, SUM(quantity*pic.price) as total "
								+ "FROM shopping_cart sc, products_in_cart pic, person per, product p, state s "
								+ "WHERE per.id = sc.person_id "
								+ "AND sc.id = pic.cart_id "
								+ "AND sc.is_purchased = TRUE " 
								+ "AND p.id = pic.product_id "
                                + "AND per.state_id = s.id "
								+ "GROUP BY s.id) "
							+ "SELECT state_name AS name, s.id, COALESCE(sales.total, 0) AS total "
							+ "FROM state s "
							+ "LEFT JOIN sales ON s.id = sales.temp_id "
							+ "ORDER BY name ASC OFFSET " + row_offset + "";
					} 
					
					/****************** Top-K order by total sales ******************/
					else{									
						row_query = "WITH sales AS (SELECT s.id AS temp_id, state_name AS name, SUM(quantity*pic.price) as total "
								+ "FROM shopping_cart sc, products_in_cart pic, person per, product p, state s "
								+ "WHERE per.id = sc.person_id "
								+ "AND sc.id = pic.cart_id "
								+ "AND sc.is_purchased = TRUE " 
								+ "AND p.id = pic.product_id "
                                + "AND per.state_id = s.id "
								+ "GROUP BY s.id) "
							+ "SELECT state_name AS name, s.id, COALESCE(sales.total, 0) AS total "
							+ "FROM state s "
							+ "LEFT JOIN sales ON s.id = sales.temp_id "
							+ "ORDER BY total DESC OFFSET " + row_offset + "";
				
						filter_query = "WITH filter_table AS (SELECT p.id AS filter_id, product_name, SUM(quantity*pic.price) AS total "
								+ "FROM product p, products_in_cart pic "
								+ "WHERE p.id = pic.product_id "
								+ "GROUP BY p.id) "
							+ "SELECT p.product_name, p.id, COALESCE(filter_table.total, 0) AS total "
							+ "FROM product p "
                        	+ "LEFT JOIN filter_table ON p.id = filter_table.filter_id "
                        	+ "ORDER BY total DESC OFFSET " + col_offset + "";
					
					}
				}
			}
						
			/****************** Category is chosen (filter applied) ******************/
			else{
				
				/****************** Customers ******************/
				
				if(row_menu.equals("Customers") || row_menu.equals("null") || row_menu == null){
					/****************** Alphabetical order ******************/
					if(col_menu.equals("Alphabetical") || col_menu.equals("null") || col_menu == null){	
						row_query = "WITH sales AS (SELECT per.id AS temp_id, person_name AS name, SUM(quantity*pic.price) as total "
								+ "FROM shopping_cart sc, products_in_cart pic, person per, product p, category c "
								+ "WHERE per.id = sc.person_id "
								+ "AND sc.id = pic.cart_id "
								+ "AND sc.is_purchased = TRUE " 
								+ "AND p.id = pic.product_id "
								+ "AND p.category_id = c.id "
								+ "AND category_name = '" + filter + "'"
								+ " GROUP BY per.id) "
							+ "SELECT person_name AS name, per.id, COALESCE(sales.total, 0) AS total "
							+ "FROM person per "
							+ "LEFT JOIN sales ON per.id = sales.temp_id "
							+ "ORDER BY name ASC OFFSET " + row_offset + "";
						
				 		filter_query = "WITH filter_table AS (SELECT p.id AS filter_id, product_name, SUM(quantity*pic.price) AS total "
								+ "FROM product p, products_in_cart pic, category  "
								+ "WHERE p.id = pic.product_id "
	                   			+ "AND category_id = category.id "
	   							+ "AND category_name = '" + filter + "'"
								+ " GROUP BY p.id) "
							+ "SELECT p.product_name, p.id, COALESCE(filter_table.total, 0) AS total "
							+ "FROM product p "	
                        	+ "LEFT JOIN filter_table ON p.id = filter_table.filter_id "
                        	+ "ORDER BY p.product_name ASC OFFSET " + col_offset + ""; 
					}	
					
					/****************** Top-K order by total sales ******************/
					else{	
						row_query = "WITH sales AS (SELECT per.id AS temp_id, person_name AS name, SUM(quantity*pic.price) as total "
								+ "FROM shopping_cart sc, products_in_cart pic, person per, product p, category c "
								+ "WHERE per.id = sc.person_id "
								+ "AND sc.id = pic.cart_id "
								+ "AND sc.is_purchased = TRUE " 
								+ "AND p.id = pic.product_id "
								+ "AND p.category_id = c.id "
								+ "AND category_name = '" + filter + "'"
								+ " GROUP BY per.id) "
							+ "SELECT person_name AS name, per.id, COALESCE(sales.total, 0) AS total "
							+ "FROM person per "
							+ "LEFT JOIN sales ON per.id = sales.temp_id "
							+ "ORDER BY total DESC OFFSET " + row_offset + "";
						
						filter_query = "WITH filter_table AS (SELECT p.id AS filter_id, product_name, SUM(quantity*pic.price) AS total "
								+ "FROM product p, products_in_cart pic, category  "
								+ "WHERE p.id = pic.product_id "
	                   			+ "AND category_id = category.id "
	   							+ "AND category_name = '" + filter + "'"
								+ " GROUP BY p.id) "
							+ "SELECT p.product_name, p.id, COALESCE(filter_table.total, 0) AS total "
							+ "FROM product p "	
                        	+ "LEFT JOIN filter_table ON p.id = filter_table.filter_id "
                        	+ "ORDER BY total DESC OFFSET " + col_offset + ""; 
					}
				}
				
				/****************** States ******************/
				else{
					
					/****************** Alphabetical order ******************/
					if(col_menu.equals("Alphabetical") || col_menu.equals("null") || col_menu == null){	
						row_query = "WITH sales AS (SELECT s.id AS temp_id, state_name AS name, SUM(quantity*pic.price) as total "
								+ "FROM shopping_cart sc, products_in_cart pic, person per, product p, state s, category c "
								+ "WHERE per.id = sc.person_id "
								+ "AND sc.id = pic.cart_id "
								+ "AND sc.is_purchased = TRUE " 
								+ "AND p.id = pic.product_id "
                                + "AND per.state_id = s.id "
                             	+ "AND p.category_id = c.id "
         						+ "AND category_name = '" + filter + "'"
								+ " GROUP BY s.id) "
							+ "SELECT state_name AS name, s.id, COALESCE(sales.total, 0) AS total "
							+ "FROM state s "
							+ "LEFT JOIN sales ON s.id = sales.temp_id "
							+ "ORDER BY state_name ASC OFFSET " + row_offset + "";
						
						filter_query = "WITH filter_table AS (SELECT p.id AS filter_id, product_name, SUM(quantity*pic.price) AS total "
								+ "FROM product p, products_in_cart pic, category  "
								+ "WHERE p.id = pic.product_id "
	                   			+ "AND category_id = category.id "
	   							+ "AND category_name = '" + filter + "'"
								+ " GROUP BY p.id) "
							+ "SELECT p.product_name, p.id, COALESCE(filter_table.total, 0) AS total "
							+ "FROM product p "	
                        	+ "LEFT JOIN filter_table ON p.id = filter_table.filter_id "
                        	+ "ORDER BY p.product_name ASC OFFSET " + col_offset + ""; 
					}
					
					/****************** Top-K order by total sales ******************/
					else{
						row_query = "WITH sales AS (SELECT s.id AS temp_id, state_name AS name, SUM(quantity*pic.price) as total "
								+ "FROM shopping_cart sc, products_in_cart pic, person per, product p, state s, category c "
								+ "WHERE per.id = sc.person_id "
								+ "AND sc.id = pic.cart_id "
								+ "AND sc.is_purchased = TRUE " 
								+ "AND p.id = pic.product_id "
                                + "AND per.state_id = s.id "
                             	+ "AND p.category_id = c.id "
         						+ "AND category_name = '" + filter + "'"
								+ " GROUP BY s.id) "
							+ "SELECT state_name AS name, s.id, COALESCE(sales.total, 0) AS total "
							+ "FROM state s "
							+ "LEFT JOIN sales ON s.id = sales.temp_id "
							+ "ORDER BY total DESC OFFSET " + row_offset + "";
				
						filter_query = "WITH filter_table AS (SELECT p.id AS filter_id, product_name, SUM(quantity*pic.price) AS total "
								+ "FROM product p, products_in_cart pic, category  "
								+ "WHERE p.id = pic.product_id "
	                   			+ "AND category_id = category.id "
	   							+ "AND category_name = '" + filter + "'"
								+ " GROUP BY p.id) "
							+ "SELECT p.product_name, p.id, COALESCE(filter_table.total, 0) AS total "
							+ "FROM product p "	
                        	+ "LEFT JOIN filter_table ON p.id = filter_table.filter_id "
                        	+ "ORDER BY total DESC OFFSET " + col_offset + "";  
					}
				}
			}
			
			/* Execute the queries */
			row_query_start = System.nanoTime();
			row_rs = row_stmt.executeQuery(row_query);
			row_query_end = System.nanoTime();
			
			filter_query_start = System.nanoTime();
			filter_rs = filter_stmt.executeQuery(filter_query);
			filter_query_end = System.nanoTime();
			
			
			/* Remember the last selected options by user */
			String row_select = request.getParameter("row_select");
			String col_select = request.getParameter("col_select");
			
			if (row_select != null && row_select.equals("set")) {
				 session.setAttribute("row_menu", request.getParameter("row_menu")); 
			}
			if (col_select != null && col_select.equals("set")) {
				 session.setAttribute("col_menu", request.getParameter("col_menu")); 
			} %>
		
			<table>
				<form method="GET">
					<input type="hidden" name="row_select" value="set"/> 
					<select name = "row_menu" <%=disabled %>>
						<option value="Customers"<% if(session.getAttribute("row_menu") == null || session.getAttribute("row_menu").equals("Customers")) {
									%>selected='selected'<%  } %>>Customers</option> 
						<option value="States" <% if(!(session.getAttribute("row_menu") == null) && session.getAttribute("row_menu").equals("States")) {
									%>selected='selected'<%  } %>>States</option> 
					</select>		
					
			   		<select name="filter" <%=disabled %>>
						<option value="All Categories">All Categories</option>
					<% 	category_query_start = System.nanoTime();
						category_rs = category_stmt.executeQuery(category_query);
						category_query_end= System.nanoTime();
                        while (category_rs.next()) {
                    	    if ((category_rs.getString("category_name")).equals(filter)) {
                    	    	%><option selected='selected' value="<%=category_rs.getString("category_name")%>"> <%=category_rs.getString("category_name")%></option><%
                    	    }
                    	    else {
                    	    	%><option value="<%=category_rs.getString("category_name")%>"> <%=category_rs.getString("category_name")%></option><%
                        	}
                        } %>
					</select> 
					
					<input type="hidden" name="col_select" value="set"/>
					<select name="col_menu" <%=disabled %>>
						<option value="Alphabetical"<% if(session.getAttribute("col_menu") == null || session.getAttribute("col_menu").equals("Alphabetical")) {
									%>selected='selected'<% 
								} %>>Alphabetical</option> 
						<option value="Top-K"<% if(!(session.getAttribute("col_menu") == null || session.getAttribute("col_menu").equals("Alphabetical"))) { 
									%>selected='selected'<%  
								} %>>Top-K</option>
					</select>
					<input type="submit" value="Run Query" <%=disabled %>/>		
			   	</form>		
			</table>
			<br>
			
			<%
			
			if(disabled.equals("disabled")){
				%><table cellspacing = "5px"><tr>
					<td valign="top"><jsp:include page="menu.jsp"></jsp:include></td>
					<td>
					<h3> If you are finished with analytics, you may navigate to another page.</h3></td>
					
					</tr>
				</table><%
			}
			else{
				%><table cellspacing = "5px"><tr>
				<td valign="top"><jsp:include page="menu.jsp"></jsp:include></td>
				<td>
				<h3> Click on any of the links on the left to navigate away from this page.</h3></td>
				
				</tr>
				</table><%
			}
			
			
			/* Handle the Next 20 buttons */
			int row_count = 0;
			int col_count = 0;
			
			while(row_rs.next()) {
			    row_count++;
			}
			
			while(filter_rs.next()) {
			    col_count++;
			}
			
			row_rs.beforeFirst();
			filter_rs.beforeFirst();
			
			/* Prepare variables for the button checks */
			int offset_row = Integer.valueOf(row_offset);
			int offset_col = Integer.valueOf(col_offset);
			boolean allow_next_20;
			boolean allow_next_10;

			if(offset_row == 0){
				offset_row = 20;
			}
			if(offset_col == 0){
				offset_col = 10;
			}
			if((row_count - 20) > 0){
				allow_next_20 = true;
			}
			else{
				allow_next_20 = false;
			}
			
			if((col_count - 10) > 0){
				allow_next_10 = true;
			}
			else{
				allow_next_10 = false;
			}
			int temp_offset = 0;
			%> <table><tr> <%
			if(allow_next_20)
			{
				
				 temp_offset = Integer.valueOf(row_offset) + 20;
				%>
				<th>		
			   	<form method="GET">
					<input type ="hidden" name="row_offset_select" value="set"/>
					<input type ="hidden" name="row_offset" value="<%=temp_offset%>"/>
					<input type ="hidden" name="col_offset" value ="<%=col_offset %>"/>
					<input type ="hidden" name="col_menu" value="<%=col_menu %>"/>
					<input type ="hidden" name="row_menu" value="<%=row_menu %>"/> 
					<input type="hidden" name="filter" value="<%=filter %>"/>
					<button type="submit">Next 20 <%=row_menu %></button>
				</form>
				</th><%
			} %>
			<%
					
			temp_offset = 0;
			if(allow_next_10)
			{
				temp_offset = Integer.valueOf(col_offset) + 10;
			}
			else{
				temp_offset = Integer.valueOf(col_offset);
			}
	
			%>

			<th>
			   	<form method="GET">
					<input type ="hidden" name="col_offset_select" value="set"/>
					<input type ="hidden" name="row_offset" value="<%=row_offset%>"/>
					<input type ="hidden" name="col_offset" value ="<%=temp_offset %>"/>
					<input type="hidden" name="col_menu" value="<%=col_menu %>"/>
					<input type="hidden" name="row_menu" value="<%=row_menu %>"/> 
					<input type="hidden" name="filter" value="<%=filter %>"/>
					<input type="submit" value="Next 10 Products"/>
				</form>
			</th>
			
			<%
			
			%> </table></tr> <%
			String row_offset_select = request.getParameter("row_offset_select");
			String col_offset_select = request.getParameter("col_offset_select");
			
			if(row_offset_select != null && row_offset_select.equals("set")){
				session.setAttribute("row_offset", request.getParameter("row_offset"));
			}
			if(col_offset_select != null && col_offset_select.equals("set")){
				session.setAttribute("col_offset", request.getParameter("col_offset"));
			}	
		

			/****************** All categories (default) ******************/
			if(filter == null || filter.equals("All Categories") || filter.equals("null") || filter.equals("all")) {
				/****************** Customers ******************/
				if(row_menu.equals("Customers") || row_menu.equals("null") || row_menu == null){
					/****************** Alphabetical order ******************/
					if(col_menu.equals("Alphabetical") || col_menu.equals("null") || col_menu == null){	
						
						%>
						
						<!-- TABLE DISPLAY  -->
						<table border="1">
						<tr>
							<th>Customers</th>
					<%	int i = 0; 
						while(filter_rs.next() && i < 10){ 
							i++; %>
							<td>
								<%=filter_rs.getString("product_name")%> ($<%=filter_rs.getDouble("total")%>)
							</td>	
						<% } %>
						</tr>
						
						<tr> <%
						PreparedStatement pstmt = conn.prepareStatement("SELECT SUM(quantity*pic.price) AS total "
								+ "FROM shopping_cart sc, products_in_cart pic, person per, product p "
								+ "WHERE per.id = ? "
								+ "AND sc.id = pic.cart_id "
								+ "AND sc.is_purchased = TRUE "
								+ "AND per.id = sc.person_id "
								+ "AND p.id = pic.product_id "
								+ "AND p.id = ? ");
						
						int currID = 0;
						int prodID = 0;
						int j = 0;
						String currName;
						while(row_rs.next() && j <20){ 
							j++;
							int k = 0;
							filter_rs.beforeFirst(); 
							%> <tr><td><%=row_rs.getString("name") %> ($<%=row_rs.getDouble("total")%>)</td> <%
							while(filter_rs.next() && k < 10){
								k++;
								currID = row_rs.getInt("id");
								currName = filter_rs.getString("product_name");
								prodID = filter_rs.getInt("id");
								pstmt.setInt(1, currID);
								pstmt.setInt(2, prodID);
								
								query_start = System.nanoTime();
								rs = pstmt.executeQuery();	
								query_end = System.nanoTime();
							%>
		
							<% while(rs.next()){
								if(rs.getDouble("total")!= 0){ %>
									<td> <%=rs.getDouble("total") %> </td>	
								<% } else { %>
									<td>0.0</td>
								<%	} %>
							<%} 
							}%> </tr>
							
					<% } %> </tr>
					</table>	
				<% }				
					
					/****************** Top-K order by total sales ******************/
					else{
		
						%><!-- TABLE DISPLAY  -->
						<table border="1">
						<tr>
							<th>Customers</th>
					<% 	int i = 0;
						while(filter_rs.next() && i < 10){ 
							i++; %>
							<td>
								<%=filter_rs.getString("product_name")%> ($<%=filter_rs.getDouble("total")%>)
							</td>	
						<% } %>
						</tr>
						
						<tr> <%
						PreparedStatement pstmt = conn.prepareStatement("SELECT SUM(quantity*pic.price) AS total "
								+ "FROM shopping_cart sc, products_in_cart pic, person per, product p "
								+ "WHERE per.id = ? "
								+ "AND sc.id = pic.cart_id "
								+ "AND sc.is_purchased = TRUE "
								+ "AND per.id = sc.person_id "
								+ "AND p.id = pic.product_id "
								+ "AND p.id = ? ");
						
						int currID = 0;
						int prodID = 0;
						int j = 0;
						String currName;
						while(row_rs.next() && j < 20){
							j++;
							int k = 0;
							filter_rs.beforeFirst(); 
							%> <tr><td><%=row_rs.getString("name") %>  ($<%=row_rs.getDouble("total")%>)</td> <%
							while(filter_rs.next() && k < 10){
								currID = row_rs.getInt("id");
								k++;
								currName = filter_rs.getString("product_name");
								prodID = filter_rs.getInt("id");
								pstmt.setInt(1, currID);
								pstmt.setInt(2, prodID);

								query_start = System.nanoTime();
								rs = pstmt.executeQuery();	
								query_end = System.nanoTime();				
							%>
		
							<% while(rs.next()){
								if(rs.getDouble("total")!= 0){ %>
									<td> <%=rs.getDouble("total") %> </td>	
								<% } else { %>
									<td>0.0</td>
								<%	} %>
							<%} 
							}%> </tr>
							
					<% } %> </tr>
					</table><%		
					}
				}
				
		
		
				/****************** States ******************/
				else{
					/****************** Alphabetical order ******************/
					if(col_menu.equals("Alphabetical") || col_menu.equals("null") || col_menu == null){		
						%><!-- TABLE DISPLAY  -->
						<table border="1">
						<tr>
							<th>States</th>
					<%	int i = 0; 
						while(filter_rs.next() && i < 10){ 
							i++; %>
							<td>
								<%=filter_rs.getString("product_name")%> ($<%=filter_rs.getDouble("total")%>)
							</td>	
						<% } %>
						</tr>
						
						<tr> <%
						PreparedStatement pstmt = conn.prepareStatement("SELECT SUM(quantity*pic.price) AS total "
								+ "FROM shopping_cart sc, products_in_cart pic, person per, product p, state s "
								+ "WHERE s.id = ? "
								+ "AND s.id = per.state_id "
								+ "AND sc.id = pic.cart_id "
								+ "AND sc.is_purchased = TRUE "
								+ "AND per.id = sc.person_id "
								+ "AND p.id = pic.product_id "
								+ "AND p.id = ? ");
						
						int currID = 0;
						int prodID = 0;
						String currName;
						int j = 0;
						while(row_rs.next() && j < 20){ 
							j++;
							int k = 0;
							filter_rs.beforeFirst(); 
							%> <tr><td><%=row_rs.getString("name") %> ($<%=row_rs.getDouble("total")%>)</td> <%
							while(filter_rs.next() && k < 10){
								k++;
								currID = row_rs.getInt("id");
								currName = filter_rs.getString("product_name");
								prodID = filter_rs.getInt("id");
								pstmt.setInt(1, currID);
								pstmt.setInt(2, prodID);

								query_start = System.nanoTime();
								rs = pstmt.executeQuery();	
								query_end = System.nanoTime();				
							%>
		
							<% while(rs.next()){
								if(rs.getDouble("total")!= 0){ %>
									<td> <%=rs.getDouble("total") %> </td>	
								<% } else { %>
									<td>0.0</td>
								<%	} %>
							<%} 
							}%> </tr>
							
					<% } %> </tr>
					</table><%
						
					} 
					/****************** Top-K order by total sales ******************/
					else{
						%><!-- TABLE DISPLAY  -->
						<table border="1">
						<tr>
							<th>States</th>
					<% 	int i = 0;
						while(filter_rs.next() && i < 10){ 
							i++; %>
							<td>
								<%=filter_rs.getString("product_name")%> ($<%=filter_rs.getDouble("total")%>)
							</td>	
						<% } %>
						</tr>
						
						<tr> <%
						PreparedStatement pstmt = conn.prepareStatement("SELECT SUM(quantity*pic.price) AS total "
								+ "FROM shopping_cart sc, products_in_cart pic, person per, product p, state s "
								+ "WHERE s.id = ? "
								+ "AND s.id = per.state_id "
								+ "AND sc.id = pic.cart_id "
								+ "AND sc.is_purchased = TRUE "
								+ "AND per.id = sc.person_id "
								+ "AND p.id = pic.product_id "
								+ "AND p.id = ? ");
						
						int currID = 0;
						int prodID = 0;
						int j = 0;
						String currName;
						while(row_rs.next() && j < 20){ 
							filter_rs.beforeFirst(); 
							j++;
							int k = 0;
							%> <tr><td><%=row_rs.getString("name") %> ($<%=row_rs.getDouble("total")%>)</td> <%
							while(filter_rs.next() && k < 10){
								k++;
								currID = row_rs.getInt("id");
								currName = filter_rs.getString("product_name");
								prodID = filter_rs.getInt("id");
								pstmt.setInt(1, currID);
								pstmt.setInt(2, prodID);

								query_start = System.nanoTime();
								rs = pstmt.executeQuery();	
								query_end = System.nanoTime();				
							%>
		
							<% while(rs.next()){
								if(rs.getDouble("total")!= 0){ %>
									<td> <%=rs.getDouble("total") %> </td>	
								<% } else { %>
									<td>0.0</td>
								<%	} %>
							<%} 
							}%> </tr>
							
					<% } %> </tr>
					</table><%
					}
				}
			}
			
			
			/****************** Category is chosen (filter applied) ******************/
			else{
				/****************** Customers ******************/
				if(row_menu.equals("Customers") || row_menu.equals("null") || row_menu == null){
					/****************** Alphabetical order ******************/
					if(col_menu.equals("Alphabetical") || col_menu.equals("null") || col_menu == null){	
						
						
						%><!-- TABLE DISPLAY  -->
						<table border="1">
						<tr>
							<th>Customers</th>
					<%	int i = 0; 
						while(filter_rs.next() && i < 10){ 
							i++; %>
							<td>
								<%=filter_rs.getString("product_name")%> ($<%=filter_rs.getDouble("total")%>)
							</td>	
						<% } %>
						</tr>
						
						<tr> <%
						PreparedStatement pstmt = conn.prepareStatement("SELECT COALESCE(SUM(quantity*pic.price), 0) AS total "
								+ "FROM shopping_cart sc, products_in_cart pic, person per, product p, category c "
								+ "WHERE per.id = ? "
								+ "AND sc.id = pic.cart_id "
								+ "AND c.category_name = '" + filter + "'"
								+ " AND c.id = p.category_id "
								+ "AND sc.is_purchased = TRUE "
								+ "AND per.id = sc.person_id "
								+ "AND p.id = pic.product_id "
								+ "AND p.id = ? ");
					
						int currID = 0;
						int prodID = 0;
						int j = 0;
						String currName;
						while(row_rs.next() && j < 20){ 
							filter_rs.beforeFirst(); 
							j++;
							int k = 0;
							%> <tr><td><%=row_rs.getString("name") %> ($<%=row_rs.getDouble("total")%>)</td> <%
							while(filter_rs.next() && k <10){
								k++;
								currID = row_rs.getInt("id");
								currName = filter_rs.getString("product_name");
								prodID = filter_rs.getInt("id");
								pstmt.setInt(1, currID);
								pstmt.setInt(2, prodID);

								query_start = System.nanoTime();
								rs = pstmt.executeQuery();	
								query_end = System.nanoTime();				
							%>
		
							<% while(rs.next()){
								if(rs.getDouble("total")!= 0){ %>
									<td> <%=rs.getDouble("total") %> </td>	
								<% } else { %>
									<td>0.0</td>
								<%	} %>
							<%} 
							}%> </tr>
							
					<% } %> </tr>
					</table><%
						
						
					}	
					
					/****************** Top-K order by total sales ******************/
					else{
						
						%><!-- TABLE DISPLAY  -->
						<table border="1">
						<tr>
							<th>Customers</th>
					<% 	int i = 0;
						while(filter_rs.next() && i < 10){ 
							i++; %>
							<td>
								<%=filter_rs.getString("product_name")%> ($<%=filter_rs.getDouble("total")%>)
							</td>	
						<% } %>
						</tr>
						
						<tr> <%
						PreparedStatement pstmt = conn.prepareStatement("SELECT COALESCE(SUM(quantity*pic.price), 0) AS total "
								+ "FROM shopping_cart sc, products_in_cart pic, person per, product p, category c "
								+ "WHERE per.id = ? "
								+ "AND sc.id = pic.cart_id "
								+ "AND c.category_name = '" + filter + "'"
								+ " AND c.id = p.category_id "
								+ "AND sc.is_purchased = TRUE "
								+ "AND per.id = sc.person_id "
								+ "AND p.id = pic.product_id "
								+ "AND p.id = ? ");
						
						int currID = 0;
						int prodID = 0;
						int j = 0;
						String currName;
						while(row_rs.next() && j < 20){ 
							filter_rs.beforeFirst(); 
							j++;
							int k = 0;
							%> <tr><td><%=row_rs.getString("name") %>  ($<%=row_rs.getDouble("total")%>)</td> <%
							while(filter_rs.next() && k < 10){
								k++;
								currID = row_rs.getInt("id");
								currName = filter_rs.getString("product_name");
								prodID = filter_rs.getInt("id");
								pstmt.setInt(1, currID);
								pstmt.setInt(2, prodID);

								query_start = System.nanoTime();
								rs = pstmt.executeQuery();	
								query_end = System.nanoTime();				
							%>
		
							<% while(rs.next()){
								if(rs.getDouble("total")!= 0){ %>
									<td> <%=rs.getDouble("total") %> </td>	
								<% } else { %>
									<td>0.0</td>
								<%	} %>
							<%} 
							}%> </tr>
							
					<% } %> </tr>
					</table><%						
					}
				}
				
				/****************** States ******************/
				else{
					/* Alphabetical order */
					if(col_menu.equals("Alphabetical") || col_menu.equals("null") || col_menu == null){	
						%><!-- TABLE DISPLAY  -->
						<table border="1">
						<tr>
							<th>States</th>
					<%	int i = 0; 
						while(filter_rs.next() && i < 10){ 
							i++; %>
							<td>
								<%=filter_rs.getString("product_name")%> ($<%=filter_rs.getDouble("total")%>)
							</td>	
						<% } %>
						</tr>
						
						<tr> <%
						PreparedStatement pstmt = conn.prepareStatement("SELECT COALESCE(SUM(quantity*pic.price), 0) AS total "
								+ "FROM shopping_cart sc, products_in_cart pic, person per, product p, category c, state s "
								+ "WHERE s.id = ? "
								+ "AND s.id = per.state_id "
								+ "AND sc.id = pic.cart_id "
								+ "AND c.category_name = '" + filter + "'"
								+ " AND c.id = p.category_id "
								+ "AND sc.is_purchased = TRUE "
								+ "AND per.id = sc.person_id "
								+ "AND p.id = pic.product_id "
								+ "AND p.id = ? ");
						
						int currID = 0;
						int prodID = 0;
						int j = 0;
						String currName;
						while(row_rs.next() && j < 20){ 
							filter_rs.beforeFirst(); 
							j++;
							int k = 0;
							%> <tr><td><%=row_rs.getString("name") %> ($<%=row_rs.getDouble("total")%>)</td> <%
							while(filter_rs.next() && k < 10){
								k++;
								currID = row_rs.getInt("id");
								currName = filter_rs.getString("product_name");
								prodID = filter_rs.getInt("id");
								pstmt.setInt(1, currID);
								pstmt.setInt(2, prodID);

								query_start = System.nanoTime();
								rs = pstmt.executeQuery();	
								query_end = System.nanoTime();				
							%>
		
							<% while(rs.next()){
								if(rs.getDouble("total")!= 0){ %>
									<td> <%=rs.getDouble("total") %> </td>	
								<% } else { %>
									<td>0.0</td>
								<%	} %>
							<%} 
							}%> </tr>
							
					<% } %> </tr>
					</table><%
						
						
					}
					
					/****************** Top-K order by total sales ******************/
					else{
						%><!-- TABLE DISPLAY  -->
						<table border="1">
						<tr>
							<th>States</th>
					<%	int i = 0; 
						while(filter_rs.next() && i < 10){ 
							i++; %>
							<td>
								<%=filter_rs.getString("product_name")%> ($<%=filter_rs.getDouble("total")%>)
							</td>	
						<% } %>
						</tr>
						
						<tr> <%
						PreparedStatement pstmt = conn.prepareStatement("SELECT COALESCE(SUM(quantity*pic.price), 0) AS total "
								+ "FROM shopping_cart sc, products_in_cart pic, person per, product p, category c, state s "
								+ "WHERE s.id = ? "
								+ "AND s.id = per.state_id "
								+ "AND sc.id = pic.cart_id "
								+ "AND c.category_name = '" + filter + "'"
								+ " AND c.id = p.category_id "
								+ "AND sc.is_purchased = TRUE "
								+ "AND per.id = sc.person_id "
								+ "AND p.id = pic.product_id "
								+ "AND p.id = ? ");
						
						int currID = 0;
						int prodID = 0;
						int j = 0;
						String currName;
						while(row_rs.next() && j < 20){ 
							filter_rs.beforeFirst(); 
							j++;
							int k = 0;
							%> <tr><td><%=row_rs.getString("name") %>  ($<%=row_rs.getDouble("total")%>)</td> <%
							while(filter_rs.next() && k < 10){
								k++;
								currID = row_rs.getInt("id");
								currName = filter_rs.getString("product_name");
								prodID = filter_rs.getInt("id");
								pstmt.setInt(1, currID);
								pstmt.setInt(2, prodID);

								query_start = System.nanoTime();
								rs = pstmt.executeQuery();	
								query_end = System.nanoTime();				
							%>
		
							<% while(rs.next()){
								if(rs.getDouble("total")!= 0){ %>
									<td> <%=rs.getDouble("total") %> </td>	
								<% } else { %>
									<td>0.0</td>
								<%	} %>
							<%} 
							}%> </tr>
							
					<% } %> </tr>
					</table><%
						
						
					}
				}
			} 
			
			long program_end = System.nanoTime();
			
			/* Compute the runtimes of each query */
			long query_time = (query_start - query_end)/(-1000000);
			long row_query_time = (row_query_start - row_query_end)/(-1000000);
			long filter_query_time = (filter_query_start - filter_query_end)/(-1000000);
			long category_query_time = (category_query_start - category_query_end)/(-1000000);
			long program_time = (program_start - program_end)/(-1000000);
			
			System.out.println("Query runtime: " + query_time + " ms");
			System.out.println("Row_Query runtime: " + row_query_time + " ms");
			System.out.println("Filter_Query runtime: " + filter_query_time + " ms");
			System.out.println("Category_Query runtime: " + category_query_time + " ms");
			System.out.println("Program runtime: " + program_time + " ms\n");
			
			%>

	 <% } 
		else { %>
			<h3>This page is available to owners only</h3>
		<%
		}  
	}
	else { %>
			<h3>Please <a href = "./login.jsp">login</a> before viewing the page</h3>
	<%} %>
</body>
</html>