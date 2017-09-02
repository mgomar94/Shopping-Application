<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="ucsd.shoppingApp.models.* , java.util.*" %>
<%@page import="java.sql.Connection, ucsd.shoppingApp.ConnectionManager, ucsd.shoppingApp.*"%>

	<%@ page import="java.sql.*"%>
	<%@ page import="java.util.List" %>
	<%@ page import="java.util.ArrayList" %>		
	<% 
			System.out.println("Success");
			try {
				Class.forName("org.postgresql.Driver");
			} catch (Exception e){
				System.out.println("Driver error");
			}
			Connection conn = null;
		    conn = DriverManager.getConnection("jdbc:postgresql://localhost/shoppingAppDB?" +"user=postgres&password=postgres");
		    
		    String pc_query = null;
		    Statement pc_stmt = conn.createStatement();
		    
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
			
			%>