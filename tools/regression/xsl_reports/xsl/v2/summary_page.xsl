<?xml version="1.0" encoding="utf-8"?>
<!--

// Copyright (c) MetaCommunications, Inc. 2003-2004
//
// Use, modification and distribution are subject to the Boost Software 
// License, Version 1.0. (See accompanying file LICENSE_1_0.txt or copy 
// at http://www.boost.org/LICENSE_1_0.txt)

-->

<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:exsl="http://exslt.org/common"
    xmlns:func="http://exslt.org/functions"
    xmlns:set="http://exslt.org/sets"
    xmlns:meta="http://www.meta-comm.com"
    extension-element-prefixes="func exsl"
    exclude-result-prefixes="exsl func set meta"
    version="1.0">

    <xsl:import href="common.xsl"/>

    <xsl:output method="html" 
        doctype-public="-//W3C//DTD HTML 4.01 Transitional//EN" 
        encoding="utf-8" 
        indent="yes"
        />


    <xsl:param name="mode"/>
    <xsl:param name="source"/>
    <xsl:param name="run_date"/>
    <xsl:param name="comment_file"/>
    <xsl:param name="explicit_markup_file"/>
    <xsl:param name="release"/>

    <xsl:variable name="explicit_markup" select="document( $explicit_markup_file )"/>

    <!-- necessary indexes -->
    <xsl:key 
        name="library_test_name_key" 
        match="test-log" 
        use="concat( @library, '&gt;@&lt;', @test-name )"/>
    <xsl:key name="toolset_key" match="test-log" use="@toolset"/>
    <xsl:key name="test_name_key"  match="test-log" use="@test-name "/>

    <!--<xsl:variable name="expected_results" select="document( $expected_results_file )" />-->

    <!-- runs / toolsets -->
    <xsl:variable name="run_toolsets" select="meta:test_structure( /, $release )"/>

    <!-- libraries -->

    <xsl:variable name="test_case_logs" select="//test-log[ meta:is_test_log_a_test_case(.) ]"/>
    <xsl:variable name="libraries" select="set:distinct( $test_case_logs/@library )"/>

    <xsl:variable name="sorted_libraries_output">
        <xsl:for-each select="$libraries[ meta:show_library( ., $release )]">
            <xsl:sort select="." order="ascending" />
            <library><xsl:copy-of select="."/></library>
        </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="sorted_libraries" select="exsl:node-set( $sorted_libraries_output )/library/@library"/>

    <xsl:variable name="release_postfix">
        <xsl:if test="$release='yes'">
            <xsl:text>_release</xsl:text>
        </xsl:if>
    </xsl:variable>
     
    <xsl:template match="/">

        <xsl:variable name="summary_results" select="concat( 'summary_', $release_postfix, '.html' )"/>

        <!-- Summary page -->
        <html>
            <head>
                <link rel="stylesheet" type="text/css" href="../master.css" title="master" />
                <title>Boost regression summary: <xsl:value-of select="$source"/></title>
            </head>
            <frameset cols="190px,*" frameborder="0" framespacing="0" border="0">
            <frame name="tocframe" src="toc.html" scrolling="auto"/>
            <frame name="docframe" src="{$summary_results}" scrolling="auto"/>
            </frameset>
        </html>

        <!-- Summary results -->
        <xsl:message>Writing document <xsl:value-of select="$summary_results"/></xsl:message>
        
        <exsl:document href="{$summary_results}"
            method="html" 
            doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN" 
            encoding="utf-8"
            indent="yes">

            <html>
            <head>
                <link rel="stylesheet" type="text/css" href="../master.css" title="master" />
            </head>
            <body>

            <h1 class="page-title">
                <xsl:text>Summary: </xsl:text>
                <a class="hover-link" href="summary.html" target="_top"><xsl:value-of select="$source"/></a>
            </h1>

            <div class="report-info">
                <b>Report Time: </b> <xsl:value-of select="$run_date"/>
            </div>

            Unusable: <xsl:value-of select="count( $test_case_logs[ meta:test_case_status( . ) = 'unusable' ] )"/>
            Fail-unexepected: <xsl:value-of select="count( $test_case_logs[ meta:test_case_status( . ) = 'fail-unexpected' ] )"/>
            fail-unexpected-new: <xsl:value-of select="count( $test_case_logs[ meta:test_case_status( . ) = 'fail-unexpected-new' ] )"/>

            <!-- summary table -->

            <table border="0" cellspacing="0" cellpadding="0" width="1%" class="summary-table" summary="Overall summary">

            <thead>
                <xsl:call-template name="insert_runners_rows">
                    <xsl:with-param name="mode" select="'summary'"/>
                </xsl:call-template>

                <xsl:call-template name="insert_toolsets_row">
                    <xsl:with-param name="mode" select="'summary'"/>
                </xsl:call-template>
            </thead>

            <tfoot>
                <xsl:call-template name="insert_toolsets_row">
                    <xsl:with-param name="mode" select="'summary'"/>
                </xsl:call-template>
                <xsl:call-template name="insert_runners_rows">
                    <xsl:with-param name="mode" select="'summary'"/>
                </xsl:call-template>
            </tfoot>
          
            <tbody>
                <xsl:variable name="test_logs" select="$test_case_logs"/>

                <!-- for each library -->
                <xsl:for-each select="$sorted_libraries">
                    <xsl:variable name="library" select="."/>
                    <xsl:variable name="library_page" select="meta:encode_path( $library )" />
                    <xsl:variable name="current_row" select="$test_logs[ @library=$library ]"/>

                    <xsl:variable name="expected_test_count" select="count( $current_row[ generate-id(.) = generate-id( key('test_name_key',@test-name)[1] ) ] )"/>
                    <xsl:variable name="library_header">
                        <td class="library-name">
                            <a href="{$library_page}{$release_postfix}.html" class="library-link" target="_top">
                                <xsl:value-of select="$library"/>
                            </a>
                        </td>
                    </xsl:variable>

                <xsl:variable name="line_mod">
                    <xsl:choose>
                    <xsl:when test="1 = last()">
                        <xsl:text>-single</xsl:text>
                    </xsl:when>
                    <xsl:when test="generate-id( . ) = generate-id( $sorted_libraries[1] )">
                        <xsl:text>-first</xsl:text>
                    </xsl:when>
                    <xsl:when test="generate-id( . ) = generate-id( $sorted_libraries[ last() ] )">
                        <xsl:text>-last</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text></xsl:text>
                    </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>


                <tr class="summary-row{$line_mod}">
                    <xsl:copy-of select="$library_header"/>

                    <xsl:for-each select="$run_toolsets/runs/run/toolset">
                        <xsl:variable name="toolset" select="@name" />
                        <xsl:variable name="runner" select="../@runner" />

                        <xsl:variable name="current_cell" select="$current_row[ @toolset=$toolset and ../@runner = $runner ]"/>

                        <xsl:choose>
                            <xsl:when test="$mode='user'">
                                <xsl:call-template name="insert_cell_user">
                                    <xsl:with-param name="current_cell" select="$current_cell"/>
                                    <xsl:with-param name="library" select="$library"/>
                                    <xsl:with-param name="toolset" select="$toolset"/>
                                    <xsl:with-param name="expected_test_count" select="$expected_test_count"/>
                                </xsl:call-template>
                            </xsl:when>
                            <xsl:when test="$mode='developer'">
                                <xsl:call-template name="insert_cell_developer">
                                    <xsl:with-param name="current_cell" select="$current_cell"/>
                                    <xsl:with-param name="library" select="$library"/>
                                    <xsl:with-param name="toolset" select="$toolset"/>
                                    <xsl:with-param name="expected_test_count" select="$expected_test_count"/>
                                </xsl:call-template>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:for-each>
                    
                    <xsl:copy-of select="$library_header"/>
                </tr>          
                </xsl:for-each>
            </tbody>
            </table>

            <xsl:copy-of select="document( concat( 'html/summary_', $mode, '_legend.html' ) )"/>
            <xsl:copy-of select="document( 'html/make_tinyurl.html' )"/>

            </body>
            </html>
        </exsl:document>  

    </xsl:template>

    <!-- report developer status -->
    <xsl:template name="insert_cell_developer">
    <xsl:param name="current_cell"/>
    <xsl:param name="library"/>
    <xsl:param name="toolset"/>
    <xsl:param name="expected_test_count"/>

    <xsl:variable name="class">
        <xsl:choose> 
        <xsl:when test="meta:is_unusable( $explicit_markup, $library, $toolset )">
            <xsl:text>summary-unusable</xsl:text>
        </xsl:when>
        <xsl:when test="count( $current_cell ) = 0">
            <xsl:text>summary-missing</xsl:text>
        </xsl:when>
        <xsl:when test="count( $current_cell[@result='fail' and  @status='unexpected' and @is-new='no'] )">
            <xsl:text>summary-fail-unexpected</xsl:text>
        </xsl:when>
        <xsl:when test="count( $current_cell[@result='fail' and  @status='unexpected' and @is-new='yes'] )">
            <xsl:text>summary-fail-unexpected-new</xsl:text>
        </xsl:when>
        <xsl:when test="count( $current_cell[@result='success' and  @status='unexpected'] )">
            <xsl:text>summary-success-unexpected</xsl:text>
        </xsl:when>
        <xsl:when test="count( $current_cell[@status='expected'] )">
            <xsl:text>summary-expected</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="count( $current_cell )"/>
        </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
      
    <xsl:variable name="library_page" select="meta:encode_path( $library )" />

    <td class="{$class}">
        <xsl:choose>
        <xsl:when test="$class='summary-unusable'">
            <xsl:text>&#160;&#160;</xsl:text>
            <a href="{$library_page}.html" class="log-link" target="_top">
                <xsl:text>n/a</xsl:text>
            </a>          
            <xsl:text>&#160;&#160;</xsl:text>
        </xsl:when>
        <xsl:when test="$class='summary-missing'">
            <xsl:text>&#160;&#160;&#160;&#160;</xsl:text>
        </xsl:when>
        <xsl:when test="$class='summary-fail-unexpected'">
            <a href="{$library_page}.html" class="log-link" target="_top">
                <xsl:text>broken</xsl:text>
            </a>
        </xsl:when>
        <xsl:when test="$class='summary-fail-unexpected-new' ">
            <xsl:text>&#160;&#160;</xsl:text>
            <a href="{$library_page}.html" class="log-link" target="_top">
                <xsl:text>fail</xsl:text>
            </a>
            <xsl:text>&#160;&#160;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>&#160;&#160;OK&#160;&#160;</xsl:text>
        </xsl:otherwise>
        </xsl:choose>
    </td>
      
    </xsl:template>


    <!-- report user status -->
    <xsl:template name="insert_cell_user">
    <xsl:param name="current_cell"/>
    <xsl:param name="library"/>
    <xsl:param name="toolset"/>
    <xsl:param name="expected_test_count"/>
    <xsl:variable name="class">
        <xsl:choose>
        <xsl:when test="meta:is_unusable( $explicit_markup, $library, $toolset )">
            <xsl:text>summary-unusable</xsl:text>
        </xsl:when>
        <xsl:when test="count( $current_cell ) &lt; $expected_test_count">
            <xsl:text>summary-missing</xsl:text>
        </xsl:when>
        <xsl:when test="count( $current_cell[@result='fail' and @status='unexpected' ] )">
            <xsl:text>summary-user-fail-unexpected</xsl:text>
        </xsl:when>
        <xsl:when test="count( $current_cell[ @result='fail'] )">
            <xsl:text>summary-user-fail-expected</xsl:text>
        </xsl:when>
        <xsl:when test="count( $current_cell[ @result='success'] )">
            <xsl:text>summary-user-success</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message terminate="yes">
                Unknown status
                <xsl:copy-of select="$current_cell">
                </xsl:copy-of>
            </xsl:message>
        </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
      
    <xsl:variable name="library_page" select="meta:encode_path( $library )" />
    
    <td class="{$class}">
        <xsl:choose>
        <xsl:when test="$class='summary-unusable'">
            <a href="{$library_page}.html" class="log-link" target="_top">
            <xsl:text>unusable</xsl:text>
            </a>          
        </xsl:when>

        <xsl:when test="$class='summary-missing'">
            <xsl:text>missing</xsl:text>
        </xsl:when>

        <xsl:when test="$class='summary-user-fail-unexpected'">
            <a href="{$library_page}.html" class="log-link" target="_top">
            <xsl:text>unexp.</xsl:text>
            </a>
        </xsl:when>

        <xsl:when test="$class='summary-user-fail-expected'">
            <a href="{$library_page}.html" class="log-link" target="_top">
            <xsl:text>details</xsl:text>
            </a>
        </xsl:when>

        <xsl:otherwise>
            <xsl:text>&#160;</xsl:text>
        </xsl:otherwise>
        </xsl:choose>
    </td>
      
    </xsl:template>

</xsl:stylesheet>
