<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="ucsd.shoppingApp.models.* , java.util.*" %>
<%@page import="java.sql.Connection, ucsd.shoppingApp.ConnectionManager, ucsd.shoppingApp.*"%>
 
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
	<title>Super Sales Analytics</title>
</head>
<body>

	<h1>Super Analytics</h1>
	<h3>Hello <%= session.getAttribute("personName") %></h3>
	<script src="//ajax.googleapis.com/ajax/libs/jquery/1.10.2/jquery.min.js"></script>
	<%@ page import="java.sql.*"%>
	<%@ page import="java.util.List" %>
	<%@ page import="java.util.ArrayList" %>
<%
 
 
	/* Keep track of the most recent run-values */
	LinkedHashMap<String, Double> productMap = new LinkedHashMap<String, Double>();
	LinkedHashMap<String, Double> stateMap = new LinkedHashMap<String, Double>();
	LinkedHashMap<String, Double> cellMap = new LinkedHashMap<String, Double>();
 	
	if(session.getAttribute("roleName") != null) {
		 String role = session.getAttribute("roleName").toString();
		if("owner".equalsIgnoreCase(role) == true){ 
			%>
						
			<!-- Refresh page -->
			<script>	
				 function refreshPage() {			
					var xmlHttp = new XMLHttpRequest();
					var url = "newSalesAnalytics2.jsp"; 
					
					xmlHttp.onreadystatechange = function(){
						if (xmlHttp.readyState == 4){
							document.getElementById("salesAnalytics").innerHTML = this.responseText;
						}
					};		
					xmlHttp.open("GET", url, true);
					xmlHttp.send();		
				} 	
			</script>


			<input id="refreshButton" type="button" value="Refresh" style="position: fixed; top: 0px; right: 0px; font-size:20px "
					onClick="refreshPage()" />

<%
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
			Statement log_stmt;
			
			ResultSet rs = null;
			ResultSet row_rs = null;
			ResultSet filter_rs = null;
			ResultSet category_rs = null;
			ResultSet log_rs = null;
			
			String query = null;			
			String row_query = null;
			String filter_query = null;
			String category_query = "SELECT * FROM Category";
			String log_query = null;
			String delete_query = null;			
			String pc_query = null;
			
			
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
			log_stmt = conn.createStatement();
			Statement pc_stmt = conn.createStatement();
			
						
				
			 /* Update the table */ 
			pc_query = "UPDATE product_sales "
					+ "SET total = product_sales.total + log.total "
					+ "FROM log "
					+ "WHERE product_name = log.pname";
			pc_stmt.executeUpdate(pc_query);	
			
			pc_query = "INSERT INTO state_sales(total, state_id, state_name, category_id, category_name)( "
					+ "SELECT total, sid, sname, cid, cname FROM log)";
			pc_stmt.executeUpdate(pc_query);
			
			pc_query = "INSERT INTO sales(state_id, product_id, total, product_name, state_name, category_id, category_name)( "
					+ "SELECT sid, pid, total, pname, sname, cid, cname FROM log)";
			pc_stmt.executeUpdate(pc_query); 
			
			/* Grab the option parameters for later use */
			String filter = "" + request.getParameter("filter"); 	
		 	String filter2 = filter;
			session.setAttribute("filter2", filter2);
			/* Prepare the queries */
			
			/****************** All categories (default) ******************/
			if(filter == null || filter.equals("All Categories") || filter.equals("null") || filter.equals("all")) {						
					/* row_query = "SELECT id, total, state_name AS name, state_id FROM state_sales ORDER BY total DESC"; */
					row_query = "SELECT SUM(total) AS total, state_id, state_name AS name FROM state_sales GROUP BY state_id, state_name ORDER BY total DESC";
					
					filter_query = "SELECT id, total, product_name, product_id FROM product_sales ORDER BY total DESC";
					log_query = "SELECT * "
							+ "FROM log l "
							+ " GROUP BY l.id, sid, pid";	
					
		}
			/****************** Category is chosen (filter applied) ******************/
			else{
				
				filter_query = "SELECT total, product_id, product_name FROM product_sales WHERE category_name = '" + filter + "'"
								+ " UNION "
								+ "SELECT 0, product_id, product_name FROM product_sales WHERE category_name <> '" + filter + "'"
								+ " GROUP BY product_name, product_id "
								+ "ORDER BY total DESC"; 
				row_query = "SELECT SUM(total) AS total, state_id, state_name AS name FROM state_sales " 
							+ "WHERE category_name = '" + filter + "' GROUP BY state_id, state_name ORDER BY total DESC";	
				log_query = "SELECT * "
						+ "FROM log l "
						+ "WHERE l.cname = '" + filter + "'"
						+ " GROUP BY l.id, sid, pid";	
			}
			
			/* Execute the queries */
			row_query_start = System.nanoTime();
			row_rs = row_stmt.executeQuery(row_query);
			row_query_end = System.nanoTime();
			
			filter_query_start = System.nanoTime();
			filter_rs = filter_stmt.executeQuery(filter_query);
			filter_query_end = System.nanoTime(); %>
 
			<table>
				<form method="GET">
			   		<select name="filter">
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
					<input id= "runButton" type="submit" value="Run" onClick = "Run()"/>		
			   	</form>		
			</table>
			
			<table cellspacing = "5px"><tr>
				<td valign="top"><jsp:include page="menu.jsp"></jsp:include></td>
				<td>
				<h3> Click on any of the links on the left to navigate away from this page.</h3></td>
				</tr>
			</table> <%
			while(filter_rs.next()){
				productMap.put(filter_rs.getString("product_name"), filter_rs.getDouble("total"));
			}
			filter_rs.beforeFirst(); 
			%>
	<div id="salesAnalytics">
					
			<%
			/****************** All categories (default) ******************/
			if(filter == null || filter.equals("All Categories") || filter.equals("null") || filter.equals("all")) {
		     %> <!-- TABLE DISPLAY  -->
				<div id="tableDiv">
				<table border="1">
				<tr>
					<th>
						States
					</th>
			<% 	int i = 0;
				while(filter_rs.next() && i < 50){ 
					i++; %>
					<td> <%=filter_rs.getString("product_name")%> ($<%=filter_rs.getDouble("total")%>)</td>	
				<% 
					
				} %>
				</tr>
				<tr> <%
				PreparedStatement pstmt = conn.prepareStatement("SELECT COALESCE(( "
						+ "SELECT SUM(total) "
						+ "FROM sales "
						+ "WHERE product_name = ? "
						+ "AND state_name = ? "
					    + "GROUP BY state_id, product_id), 0) AS total");
				
				int currID = 0;
				int prodID = 0;
				int j = 0;
				String currName, currState;
				while(row_rs.next() && j < 56){ 
					filter_rs.beforeFirst(); 
					j++;
					int k = 0;
					%> <tr><td>
							<%=row_rs.getString("name")%> ($<%=row_rs.getDouble("total")%>)
						</td> <%
					stateMap.put(row_rs.getString("name"), row_rs.getDouble("total"));
					while(filter_rs.next() && k < 50){
						k++;
						currID = row_rs.getInt("state_id");
						currState = row_rs.getString("name");
						currName = filter_rs.getString("product_name");
						prodID = filter_rs.getInt("product_id");
						pstmt.setString(1, currName);
						pstmt.setString(2, currState);
						
						String key = "" + row_rs.getString("name") + " " + currName;
						
						query_start = System.nanoTime();
						rs = pstmt.executeQuery();	
						query_end = System.nanoTime();				
					%>
 
					<% while(rs.next()){
						 %>
						<td> <%=rs.getDouble("total")%> </td>	
					<%
						
						cellMap.put(key, rs.getDouble("total"));
					
					} 
				}%> </tr>
					
			<% } %> </tr>
			</table> 
			</div><%
				}
				
			else{
				%><!-- TABLE DISPLAY  -->
				<div id="tableDiv">
				<table border="1">
				<tr>
					<th>States</th>
			<%	int i = 0; 
				while(filter_rs.next() && i < 50){ 
					i++; %>
					<td><%=filter_rs.getString("product_name") %> ($<%=filter_rs.getDouble("total")%>) </td>	
				<% 
					productMap.put(filter_rs.getString("product_name"), filter_rs.getDouble("total"));
				} %>
				</tr>
				
				<tr> <%
				PreparedStatement pstmt = conn.prepareStatement("SELECT COALESCE(( "
						+ "SELECT SUM(total) "
						+ "FROM sales "
						+ "WHERE product_name = ? "
						+ "AND state_name = ? "
						+ "AND category_name = ? "
					    + "GROUP BY state_id, product_id), 0) AS total");
				int currID = 0;
				int prodID = 0;
				int j = 0;
				String currName, currState;
				while(row_rs.next() && j < 56){ 
					filter_rs.beforeFirst(); 
					j++;
					int k = 0;
					%> <tr><td>
							<%=row_rs.getString("name")%> ($<%=row_rs.getDouble("total")%>)
						</td> <%
					stateMap.put(row_rs.getString("name"), row_rs.getDouble("total"));
					while(filter_rs.next() && k < 50){
						k++;
						currID = row_rs.getInt("state_id");
						currState = row_rs.getString("name");
						currName = filter_rs.getString("product_name");
						prodID = filter_rs.getInt("product_id");
						pstmt.setString(1, currName);
						pstmt.setString(2, currState);
						pstmt.setString(3, filter);
 						
						String key = "" + row_rs.getString("name") + " " + currName;
						
						query_start = System.nanoTime();
						rs = pstmt.executeQuery();	
						query_end = System.nanoTime();				
					%>
 
					<% while(rs.next()){
					 %>
						<td> <%=rs.getDouble("total")%> </td>	
						
					<%
						cellMap.put(key, rs.getDouble("total"));
					
					} 
				}%> </tr>
					
			<% } %> </tr>
			</table>
			</div><%			
			}
			
			
			delete_query = "delete from log";
			log_stmt.executeUpdate(delete_query); 
			
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

			session.setAttribute("productMap", productMap);
			session.setAttribute("stateMap", stateMap);
			session.setAttribute("cellMap", cellMap);
			session.setAttribute("pm", null);
			session.setAttribute("sm", null);
			session.setAttribute("cm", null);	
 			System.out.println(stateMap);
 
 
			%>
				</div>
				
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
