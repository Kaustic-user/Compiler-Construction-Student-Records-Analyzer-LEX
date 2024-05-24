%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <math.h>
#define MAX_LENGTH 31

char givenID[MAX_LENGTH];	
int c=0;
char currID[MAX_LENGTH];
// Structure to hold course information
typedef struct {
    char courseID[31];
    int units;
    char grades[2];
} CourseInfo;

// Structure to hold student information
typedef struct {
    char studID[31];
    CourseInfo courses[500]; 
    int numCourses;
} StudentInfo;

StudentInfo student;
int numStudents = 0; //number of students
int at_least_one_tuple = 0;

%}

STUDID [A-Z]+[0-9]+
COURSEID [A-Z]+[0-9]+
UNITS [2|3|4]
CGRADE C
GRADE [A|B]
MINUS -
SPACE0 [ ]*
SPACE1 [ ]+
COMMENT "//"

%x slc
%x dollar
%x studentID
%x tuple
%x course_ID
%x unit
%x grade
%x furtherGrade
%x comment
%x invalid


%%

"$" {BEGIN(dollar);}
"//" {c++;BEGIN(comment);}
. {}

<comment>\n {BEGIN(INITIAL);}
<comment>. {;}

<dollar>\n {BEGIN(INITIAL);}
<dollar>{SPACE0} {}
<dollar>{STUDID} {
	strcpy(currID,yytext);
	if(strcmp(givenID,currID)==0 && strcmp(student.studID,"NULL")==0){
		strcpy(student.studID, currID);
		student.numCourses = 0;
	}
	
	if(at_least_one_tuple == 1){
		at_least_one_tuple=0;
		numStudents++;
	}
	printf("%s\n",yytext);
	BEGIN(studentID);

}
<dollar>{COMMENT} {c++;BEGIN(comment);}
<dollar>. {BEGIN(INITIAL);}  //handle wrong student id and no student id


<studentID>\n {BEGIN(INITIAL);}
<studentID>{SPACE0} {}
<studentID>"$" {BEGIN(dollar);}
<studentID>< {printf("%s ",yytext);BEGIN(tuple);}  
<studentID>{COMMENT} {c++;BEGIN(comment);}



<tuple>\n {BEGIN(INITIAL);}
<tuple>{SPACE0} {}
<tuple>{COURSEID} {
	printf("%s ",yytext);
	if(strcmp(student.studID,"NULL")!=0 && strcmp(student.studID ,currID)==0)
	strcpy(student.courses[student.numCourses].courseID , yytext);
	BEGIN(course_ID);
}
<tuple>{COMMENT} {c++;BEGIN(comment);}
<tuple>> {BEGIN(studentID);}
<tuple>. {BEGIN(invalid);}



<course_ID>\n {BEGIN(INITIAL);}
<course_ID>{SPACE1} {}
<course_ID>{UNITS} {
	printf("%s-",yytext);
	if(strcmp(student.studID,"NULL")!=0 && strcmp(student.studID ,currID)==0)
	student.courses[student.numCourses].units = atoi(yytext);
	BEGIN(unit);
}
<course_ID>{COMMENT} {c++;BEGIN(comment);}
<course_ID>> {BEGIN(studentID);}
<course_ID>. {BEGIN(invalid);}


<unit>\n {BEGIN(INITIAL);}
<unit>{SPACE1} {}
<unit>{GRADE} {
	printf("%s ",yytext);
	if(strcmp(student.studID,"NULL")!=0 && strcmp(student.studID ,currID)==0)
	student.courses[student.numCourses].grades[0] = yytext[0];
	BEGIN(furtherGrade);	
}
<unit>{CGRADE} {
	printf("%s ",yytext);
	if(strcmp(student.studID,"NULL")!=0 && strcmp(student.studID ,currID)==0)
	strcpy(student.courses[student.numCourses].grades , yytext);
	BEGIN(grade);
}
<unit>{COMMENT} {c++;BEGIN(comment);}
<unit>> {BEGIN(studentID);}
<unit>. {BEGIN(invalid);}


<furtherGrade>\n {BEGIN(INITIAL);}
<furtherGrade>{MINUS} {
	printf("%s ",yytext);
	if(strcmp(student.studID,"NULL")!=0 && strcmp(student.studID ,currID)==0)
	student.courses[student.numCourses].grades[1] = yytext[0];
	BEGIN(grade);
}
<furtherGrade>{SPACE0} {}
<furtherGrade>> {
	printf("%s\n ",yytext);
	at_least_one_tuple=1;
	if(strcmp(student.studID,"NULL")!=0 && strcmp(student.studID ,currID)==0){
		student.numCourses++;
	}
	BEGIN(studentID);
}
<furtherGrade>{COMMENT} {c++;BEGIN(comment);}
<furtherGrade>> {BEGIN(studentID);}
<furtherGrade>. {BEGIN(invalid);}


<grade>\n {BEGIN(INITIAL);}
<grade>{SPACE0} {}
<grade>> {
	printf("%s \n",yytext);
	at_least_one_tuple=1;
	if(strcmp(student.studID,"NULL")!=0 && strcmp(student.studID ,currID)==0){
		student.numCourses++; 
	}
	BEGIN(studentID);
}
<grade>{COMMENT} {c++;BEGIN(comment);}
<grade>> {BEGIN(studentID);}
<grade>. {BEGIN(invalid);}



<invalid>> {BEGIN(studentID);}
<invalid>{COMMENT} {c++;BEGIN(comment);}
<invalid>. {}


%%

int main(){
    char line[MAX_LENGTH];
    char firstLine[MAX_LENGTH];
    FILE *file_input= fopen("input.txt","r");
    if (file_input==NULL) {
       fprintf(stderr, "Error opening file\n");
       return 1;
    }
    
    // Read the first non-empty line
    while (fgets(line, sizeof(line), file_input) != NULL) {
        // Skip leading spaces
        char *ptr = line;
        while (isspace(*ptr)) {
            ptr++;
        }

        // If the line is not empty after skipping spaces, copy the first word
        if (*ptr != '\0') {
            char *word = strtok(ptr, " \t\n"); // Split by space, tab, or newline
            if (word != NULL) {
                strcpy(firstLine, word);
                break; // Exit the loop after copying the first word
            }
        }
    }
    
    // Close the input file
    fclose(file_input);
    //firstLine[strcspn(firstLine, "\n")] = '\0';
    strcpy(givenID,firstLine);
    printf("First non-empty line: --%s--\n", givenID);
    
    
    yyin = fopen("data.txt", "r");
    if (!yyin) {
       fprintf(stderr, "Error opening file\n");
       return 1;
    }
    strcpy(student.studID,"NULL");
    yylex();

    if(student.numCourses!=0)
    {
    	for(int i=0;i<student.numCourses;i++){
    		printf("<%s %d %s> ",student.courses[i].courseID,student.courses[i].units,student.courses[i].grades);
    	}
    }
    
    int numerator = 0;
    int unit_sum = 0;
    int unique_courses = 0;
    for(int i=0;i<student.numCourses;i++){
    	if(strcmp(student.courses[i].courseID,"NULL")!=0){
	    	unique_courses++;
	    	unit_sum += student.courses[i].units;
	    	char course_name[31];
	    	strcpy(course_name,student.courses[i].courseID);
	    	int flag = 1;
	    	for(int j=student.numCourses-1;j>=i;j--){
	    		if(strcmp(student.courses[j].courseID, course_name)==0){
	    			int u = student.courses[j].units;
	    			if(flag){
		    			switch(student.courses[j].grades[0]){
		    				case 'A':
						    	if(student.courses[j].grades[1]=='-') numerator += 8 * u;	
						    	else numerator += 10 * u;	
						    	break;
							
						case 'B':
							if(student.courses[j].grades[1]=='-') numerator += 4 * u;	
						    	else numerator += 6 * u;	
						    	break;
						case 'C':
							numerator += 2 * u;
							break;
					    	default:
							break;
					}
					flag = 0;
				}
				strcpy(student.courses[j].courseID,"NULL");
			}
	    	}
    	}
    }
    double cgpa=0;
    if(unit_sum==0) cgpa = 0;
    else cgpa = (double)(numerator*100)/(double)unit_sum;
    
    cgpa = round(cgpa);
    int gpa = (int)cgpa; 
      
    // Output file
    FILE *output = fopen("output.txt", "w");
    if (!output) {
        fprintf(stderr, "Error creating output file\n");
        return 1;
    }
    
    if(at_least_one_tuple==1)numStudents++;
    
    fprintf(output, "@%d@%d@%d@%d#\n", numStudents, c, unique_courses, gpa);

    fclose(output);

    return 0;
}
























