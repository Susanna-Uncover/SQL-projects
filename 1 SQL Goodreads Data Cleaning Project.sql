/*
Cleaning Goodreads data for a data-driven sci-fi book recommendation
*/

SELECT *
FROM PortfolioProject.dbo.Goodreads

-- Adding an ID column to improve table navigation
ALTER TABLE PortfolioProject.dbo.Goodreads
ADD id INT IDENTITY(1,1);

-- Duplicating the first row of data before renaming the columns
INSERT INTO PortfolioProject.dbo.Goodreads
VALUES (
	4.4
	, 136455
	, '0439023483'
	, 'good_reads:book'
	, 'https://www.goodreads.com/author/show/153394.Suzanne_Collins'
	, 2008
	, '/genres/young-adult|/genres/science-fiction|/genres/dystopia|/genres/fantasy|/genres/science-fiction|/genres/romance|/genres/adventure|/genres/book-club|/genres/young-adult|/genres/teen|/genres/apocalyptic|/genres/post-apocalyptic|/genres/action'
	, 'dir01/2767052-the-hunger-games.html'
	, 2958974
	, 'The Hunger Games (The Hunger Games, #1)'
	)

-- Renaming the columns 
EXEC sp_rename 'Goodreads.4#4', 'rating';
EXEC sp_rename 'Goodreads.136455', 'numberofreviews';
EXEC sp_rename 'Goodreads.0439023483', 'isbn';
EXEC sp_rename 'Goodreads.good_reads:book', 'media_type';
EXEC sp_rename 'Goodreads.https://www#goodreads#com/author/show/153394#Suzanne_Collins', 'author_url';
EXEC sp_rename 'Goodreads.2008', 'publishing_year';
EXEC sp_rename 'Goodreads./genres/young-adult|/genres/science-fiction|/genres/dystopia|/ge', 'genres';
EXEC sp_rename 'Goodreads.dir01/2767052-the-hunger-games#html', 'directory';
EXEC sp_rename 'Goodreads.2958974', 'rating_count';
EXEC sp_rename 'Goodreads.The Hunger Games (The Hunger Games, #1)', 'title';

-- Examining the table for null values
SELECT COUNT(*)-COUNT(rating) AS rating
	 , COUNT(*)-COUNT(numberofreviews) AS n_of_reviews
	 , COUNT(*)-COUNT(isbn) AS isbn
	 , COUNT(*)-COUNT(publishing_year) AS publishing_year
	 , COUNT(*)-COUNT(genres) AS genres
	 , COUNT(*)-COUNT(rating_count) AS rating_count
	 , COUNT(*)-COUNT(title) AS title
FROM PortfolioProject.dbo.Goodreads;

-- Updating the missing values to read as NULL
UPDATE PortfolioProject.dbo.Goodreads SET isbn = NULL WHERE isbn ='None';
UPDATE PortfolioProject.dbo.Goodreads SET media_type = NULL WHERE media_type ='None';
UPDATE PortfolioProject.dbo.Goodreads SET author_url = NULL WHERE author_url ='None';
UPDATE PortfolioProject.dbo.Goodreads SET title = NULL WHERE title='None';
UPDATE PortfolioProject.dbo.Goodreads SET genres = NULL WHERE genres='None';

-- Clearing the rows where most of the data is missing
DELETE FROM PortfolioProject.dbo.Goodreads WHERE media_type is null

-- Identifying duplicate values
SELECT isbn, COUNT(*)
FROM PortfolioProject.dbo.Goodreads
GROUP BY isbn
HAVING COUNT(*) > 1;

SELECT *
FROM PortfolioProject.dbo.Goodreads
WHERE isbn = '0439023483';

-- Removing duplicate rows
DELETE FROM PortfolioProject.dbo.Goodreads
WHERE isbn = '0439023483'
AND id <> (SELECT MIN(id)
           FROM PortfolioProject.dbo.Goodreads
           WHERE isbn = '0439023483');

-- Splitting out the author's column based on the author_url column
ALTER TABLE PortfolioProject.dbo.Goodreads
ADD author NVARCHAR(255);

UPDATE PortfolioProject.dbo.Goodreads
SET author = REPLACE(PARSENAME(REPLACE(author_url, ',', '.'), 1), '_', ' ');

-- Standardising the ratings column 
ALTER TABLE PortfolioProject.dbo.Goodreads
ADD rating_100 float;
UPDATE PortfolioProject.dbo.Goodreads
SET rating_100 = rating * 20

-- Cleaning up the Genres column
UPDATE PortfolioProject.dbo.Goodreads
SET genres = REPLACE(REPLACE(REPLACE(genres, '/genres/', ''), '-', ' '), '|', ' | ');

-- Exploring the most popular tags in the genres column
SELECT TOP 100
	value [word],
	COUNT(*) [#times]
FROM  PortfolioProject.dbo.Goodreads
CROSS APPLY STRING_SPLIT(Goodreads.genres, '|') 
GROUP BY value
ORDER BY COUNT(*) DESC

-- Creating filter columns based on the genre hits
ALTER TABLE PortfolioProject.dbo.Goodreads
ADD genre_fantasy NVARCHAR(255),
    genre_romance NVARCHAR(255),
    genre_young_adult NVARCHAR(255),
    genre_paranormal NVARCHAR(255),
    genre_classics NVARCHAR(255),
    genre_science_fiction NVARCHAR(255),
    genre_mystery NVARCHAR(255),
    genre_childrens NVARCHAR(255),
    genre_adventure NVARCHAR(255);

UPDATE PortfolioProject.dbo.Goodreads
SET genre_fantasy = CASE WHEN genres LIKE '%fantasy%' THEN 'Yes' ELSE 'No' END,
    genre_romance = CASE WHEN genres LIKE '%romance%' THEN 'Yes' ELSE 'No' END,
    genre_young_adult = CASE WHEN genres LIKE '%young adult%' THEN 'Yes' ELSE 'No' END,
    genre_paranormal = CASE WHEN genres LIKE '%paranormal%' THEN 'Yes' ELSE 'No' END,
    genre_classics = CASE WHEN genres LIKE '%classics%' THEN 'Yes' ELSE 'No' END,
    genre_science_fiction = CASE WHEN genres LIKE '%science fiction%' THEN 'Yes' ELSE 'No' END,
    genre_mystery = CASE WHEN genres LIKE '%mystery%' THEN 'Yes' ELSE 'No' END,
    genre_childrens = CASE WHEN genres LIKE '%childrens%' THEN 'Yes' ELSE 'No' END,
    genre_adventure = CASE WHEN genres LIKE '%adventure%' THEN 'Yes' ELSE 'No' END;

-- Delete unused columns
ALTER TABLE PortfolioProject.dbo.Goodreads
DROP COLUMN media_type, author_url, directory

-- Ordering the columns, filtering out low rating counts and missing isbn rows and non-sci-fi books
SELECT id, isbn, rating_100, rating_count, numberofreviews, title, author, publishing_year, genre_science_fiction
FROM PortfolioProject.dbo.Goodreads
WHERE genre_science_fiction ='Yes' AND rating_count > 30 AND isbn IS NOT NULL
ORDER BY rating DESC

-- Looks like both of the Stormlight Archive entries are very well-rated, let's add them to the reading list
SELECT id, isbn, rating_100, rating_count, numberofreviews, title, author, publishing_year
FROM PortfolioProject.dbo.Goodreads
WHERE author = 'Brandon Sanderson'
ORDER BY rating DESC


