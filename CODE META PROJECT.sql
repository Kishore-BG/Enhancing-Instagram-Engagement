-- 1.	Are there any tables with duplicate or missing null values? If so, how would you handle them?
SELECT * FROM photos;

select id,image_url,user_id,created_dat,count(*) as cnt
from photos
group by 1,2,3,4
having count(*) > 1;

select id,image_url,user_id,created_dat
from photos
where id is null or image_url is null or user_id is null or created_dat is null;

select * from comments;

select id,comment_text,user_id,photo_id,created_at,count(*) as cnt
from comments
group by 1,2,3,4,5
having count(*)>1;

select id,comment_text,user_id,photo_id,created_at
from comments
where id is null or comment_text is null or user_id is null or photo_id is null or created_at is null;

select * from follows;

select follower_id,followee_id,created_at,count(*) as cnt
from follows
group by 1,2,3
having count(*)>1;

select follower_id,followee_id,created_at
from follows
where follower_id is null or followee_id is null or created_at is null;

select * from likes;

select user_id,photo_id,created_at,count(*) as cnt
from likes
group by 1,2,3
having count(*)>1;

select user_id,photo_id,created_at
from likes
where user_id is null or photo_id is null or created_at is null;

select * from photo_tags;

select photo_id,tag_id,count(*) as cnt
from photo_tags
group by 1,2
having count(*) >1;
 
select photo_id,tag_id
from photo_tags
where photo_id is null or tag_id is null;

select * from tags;

select id,tag_name,created_at,count(*) as cnt
from tags
group by 1,2,3
having count(*) >1;

select id,tag_name,created_at
from tags
where id is null or tag_name is null or created_at is null;

select * from users;

select id,username,created_at,count(*) as cnt
from users
group by 1,2,3
having count(*)>1;

select id,username,created_at
from users
where id is null or username is null or created_at is null;

-- 2.	What is the distribution of user activity levels (e.g., number of posts, likes, comments) across the user base?
SELECT 
  u.username,
  COALESCE(p.total_posts, 0) AS total_posts,
  COALESCE(l.total_likes, 0) AS total_likes,
  COALESCE(c.total_comments, 0) AS total_comments,
  COALESCE(f.total_followers, 0) AS total_followers
FROM users u
LEFT JOIN (
    SELECT user_id, COUNT(*) AS total_posts
    FROM photos
    GROUP BY user_id
) p ON u.id = p.user_id
LEFT JOIN (
    SELECT p.user_id, COUNT(*) AS total_likes
    FROM photos p
    JOIN likes l ON p.id = l.photo_id
    GROUP BY p.user_id
) l ON u.id = l.user_id
LEFT JOIN (
    SELECT p.user_id, COUNT(*) AS total_comments
    FROM photos p
    JOIN comments c ON p.id = c.photo_id
    GROUP BY p.user_id
) c ON u.id = c.user_id
LEFT JOIN (
    SELECT followee_id AS user_id, COUNT(*) AS total_followers
    FROM follows
    GROUP BY followee_id
) f ON u.id = f.user_id
ORDER BY total_likes desc,total_comments desc
LIMIT 10;

-- 3.	Calculate the average number of tags per post (photo_tags and photos tables).
SELECT 
  ROUND(COUNT(pt.tag_id) * 1.0 / COUNT(DISTINCT p.id), 2) AS avg_tags_per_post
FROM photos p
LEFT JOIN photo_tags pt ON p.id = pt.photo_id;

-- 4.	Identify the top users with the highest engagement rates (likes, comments) on their posts and rank them.
SELECT 
  username,
  total_posts,
  total_likes_received,
  total_comments_received,
  like_engagement_rate,
  comment_engagement_rate,
  (like_engagement_rate + comment_engagement_rate) AS total_engagement_rate,
  RANK() OVER (ORDER BY (like_engagement_rate + comment_engagement_rate) DESC) AS engagement_rank
FROM (
    SELECT 
      u.username,
      COALESCE(p.total_posts, 0) AS total_posts,
      COALESCE(l.total_likes, 0) AS total_likes_received,
      COALESCE(c.total_comments, 0) AS total_comments_received,
      ROUND(COALESCE(l.total_likes, 0) * 1.0 / GREATEST(p.total_posts, 1), 2) AS like_engagement_rate,
      ROUND(COALESCE(c.total_comments, 0) * 1.0 / GREATEST(p.total_posts, 1), 2) AS comment_engagement_rate
    FROM users u
    LEFT JOIN (
        SELECT user_id, COUNT(*) AS total_posts
        FROM photos
        GROUP BY user_id
    ) p ON u.id = p.user_id
    LEFT JOIN (
        SELECT p.user_id, COUNT(*) AS total_likes
        FROM photos p
        JOIN likes l ON l.photo_id = p.id
        GROUP BY p.user_id
    ) l ON u.id = l.user_id
    LEFT JOIN (
        SELECT p.user_id, COUNT(*) AS total_comments
        FROM photos p
        JOIN comments c ON c.photo_id = p.id
        GROUP BY p.user_id
    ) c ON u.id = c.user_id
    WHERE COALESCE(p.total_posts, 0) > 0
) ranked
ORDER BY engagement_rank
limit 10 ;

-- 5.	Which users have the highest number of followers and followings?
SELECT 
  u.username,
  u.id as user_id,
  COALESCE(followers.total_followers, 0) AS total_followers,
  COALESCE(followings.total_followings, 0) AS total_followings
FROM users u
LEFT JOIN (
    SELECT followee_id AS user_id, COUNT(*) AS total_followers
    FROM follows
    GROUP BY followee_id
) followers ON u.id = followers.user_id
LEFT JOIN (
    SELECT follower_id AS user_id, COUNT(*) AS total_followings
    FROM follows
    GROUP BY follower_id
) followings ON u.id = followings.user_id
ORDER BY total_followings DESC,total_followers DESC,u.username asc
limit 10;

-- 6.	Calculate the average engagement rate (likes, comments) per post for each user.
SELECT 
  u.username,
  COALESCE(p.total_posts, 0) AS total_posts,
  COALESCE(l.total_likes, 0) AS total_likes,
  COALESCE(c.total_comments, 0) AS total_comments,
  ROUND(COALESCE(l.total_likes * 1.0, 0) / NULLIF(p.total_posts, 0), 2) AS avg_likes_per_post,
  ROUND(COALESCE(c.total_comments * 1.0, 0) / NULLIF(p.total_posts, 0), 2) AS avg_comments_per_post
FROM users u
LEFT JOIN (
    SELECT user_id, COUNT(*) AS total_posts
    FROM photos
    GROUP BY user_id
) p ON u.id = p.user_id
LEFT JOIN (
    SELECT p.user_id, COUNT(*) AS total_likes
    FROM photos p
    JOIN likes l ON p.id = l.photo_id
    GROUP BY p.user_id
) l ON u.id = l.user_id
LEFT JOIN (
    SELECT p.user_id, COUNT(*) AS total_comments
    FROM photos p
    JOIN comments c ON p.id = c.photo_id
    GROUP BY p.user_id
) c ON u.id = c.user_id
WHERE p.total_posts IS NOT NULL
ORDER BY avg_likes_per_post DESC, avg_comments_per_post DESC
limit 10;

-- 7.	Get the list of users who have never liked any post (users and likes tables)
SELECT distinct u.username
FROM users u
LEFT JOIN likes l ON u.id = l.user_id
WHERE l.user_id IS NULL;

-- 8.	How can you leverage user-generated content (posts, hashtags, photo tags) to create more personalized and engaging ad campaigns?
with tags as (
SELECT 
    u.id AS user_id,
    u.username,
    t.tag_name,
    COUNT(*) AS tag_usage_count
FROM users u
JOIN photos p ON u.id = p.user_id
JOIN photo_tags pt ON p.id = pt.photo_id
JOIN tags t ON pt.tag_id = t.id
GROUP BY u.id, u.username, t.tag_name
ORDER BY u.id, tag_usage_count DESC
),
ranking as(
select
user_id,
username,
tag_name,
tag_usage_count,
row_number() over(partition by user_id order by tag_usage_count desc) as rnk
from tags
)
select 
*
from ranking
where rnk =1;


-- 9. Are there any correlations between user activity levels and specific content types (e.g., photos, videos, reels)? How can this information guide content creation and curation strategies?
SELECT 
    u.id AS user_id,
    u.username,
    COUNT(DISTINCT p.id) AS total_photos_posted,
    COUNT(DISTINCT l.photo_id) AS total_likes_given,
    COUNT(DISTINCT c.id) AS total_comments_made,
    (
        SELECT COUNT(*) 
        FROM likes l2
        JOIN photos p2 ON l2.photo_id = p2.id
        WHERE p2.user_id = u.id
    ) AS total_likes_received,
    (
        SELECT COUNT(*) 
        FROM comments c2
        JOIN photos p2 ON c2.photo_id = p2.id
        WHERE p2.user_id = u.id
    ) AS total_comments_received
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
LEFT JOIN likes l ON u.id = l.user_id
LEFT JOIN comments c ON u.id = c.user_id
GROUP BY u.id, u.username
HAVING COUNT(DISTINCT p.id) > 0
ORDER BY total_photos_posted DESC;



-- 10.	Calculate the total number of likes, comments, and photo tags for each user.
SELECT 
  u.username,
  COALESCE(p.total_posts, 0) AS total_posts,
  COALESCE(l.total_likes, 0) AS total_likes,
  COALESCE(c.total_comments, 0) AS total_comments,
  COALESCE(t.total_tags, 0) AS total_photo_tags
FROM users u
LEFT JOIN (
    SELECT distinct user_id, COUNT(*) AS total_posts
    FROM photos
    GROUP BY user_id
) p ON u.id = p.user_id
LEFT JOIN (
    SELECT distinct p.user_id, COUNT(*) AS total_likes
    FROM photos p
    JOIN likes l ON p.id = l.photo_id
    GROUP BY p.user_id
) l ON u.id = l.user_id
LEFT JOIN (
    SELECT distinct p.user_id, COUNT(*) AS total_comments
    FROM photos p
    JOIN comments c ON p.id = c.photo_id
    GROUP BY p.user_id
) c ON u.id = c.user_id
LEFT JOIN (
    SELECT distinct p.user_id, COUNT(*) AS total_tags
    FROM photos p
    JOIN photo_tags pt ON p.id = pt.photo_id
    GROUP BY p.user_id
) t ON u.id = t.user_id
WHERE p.total_posts IS NOT NULL
ORDER BY total_likes DESC, total_comments DESC;

-- 11.	Rank users based on their total engagement (likes, comments, shares) over a month.
SELECT 
  u.username,
  COALESCE(l.total_likes, 0) AS total_likes,
  COALESCE(c.total_comments, 0) AS total_comments,
  (COALESCE(l.total_likes, 0) + COALESCE(c.total_comments, 0)) AS total_engagement,
  RANK() OVER (ORDER BY (COALESCE(l.total_likes, 0) + COALESCE(c.total_comments, 0)) DESC) AS engagement_rank
FROM users u
LEFT JOIN (
    SELECT distinct p.user_id, COUNT(distinct l.photo_id) AS total_likes
    FROM photos p
    JOIN likes l ON p.id = l.photo_id
    WHERE l.created_at >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
    GROUP BY p.user_id
) l ON u.id = l.user_id
LEFT JOIN (
    SELECT distinct p.user_id, COUNT(distinct c.id) AS total_comments
    FROM photos p
    JOIN comments c ON p.id = c.photo_id
    WHERE c.created_at >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
    GROUP BY p.user_id
) c ON u.id = c.user_id
ORDER BY total_engagement DESC
limit 10;

-- 12.	Retrieve the hashtags that have been used in posts with the highest average number of likes. Use a CTE to calculate the average likes for each hashtag first.
WITH tag_likes_cte AS (
  SELECT 
    t.tag_name,
    COUNT(l.user_id) * 1.0 / COUNT(DISTINCT pt.photo_id) AS avg_likes_per_post
  FROM photo_tags pt
  JOIN tags t ON pt.tag_id = t.id
  JOIN likes l ON pt.photo_id = l.photo_id
  GROUP BY t.tag_name
)
SELECT *
FROM tag_likes_cte
ORDER BY avg_likes_per_post DESC
LIMIT 10;


-- 13.	Retrieve the users who have started following someone after being followed by that person
SELECT 
  f1.follower_id AS user_id,
  f1.followee_id AS followed_back_user,
  f1.created_at AS followed_at,
  f2.created_at AS was_followed_at
FROM follows f1
JOIN follows f2 
  ON f1.follower_id = f2.followee_id 
  AND f1.followee_id = f2.follower_id
WHERE 
  f1.follower_id != f1.followee_id -- avoid self-follow
  AND f1.created_at >= f2.created_at -- followed AFTER being followed and followed at the same time
ORDER BY f1.created_at
limit 10;

-- 1.	Based on user engagement and activity levels, which users would you consider the most loyal or valuable? How would you reward or incentivize these users?
SELECT 
  u.username,
  COALESCE(p.total_posts, 0) AS total_posts,
  COALESCE(l.total_likes, 0) AS total_likes,
  ROUND(COALESCE(l.total_likes, 0) / NULLIF(p.total_posts, 0), 2) AS avg_likes_per_post,
  COALESCE(c.total_comments, 0) AS total_comments,
  ROUND(COALESCE(c.total_comments, 0) / NULLIF(p.total_posts, 0), 2) AS avg_comments_per_post,
  COALESCE(f.total_followers, 0) AS total_followers
FROM users u
LEFT JOIN (
    SELECT user_id, COUNT(*) AS total_posts
    FROM photos
    GROUP BY user_id
) p ON u.id = p.user_id
LEFT JOIN (
    SELECT p.user_id, COUNT(*) AS total_likes
    FROM photos p
    JOIN likes l ON p.id = l.photo_id
    GROUP BY p.user_id
) l ON u.id = l.user_id
LEFT JOIN (
    SELECT p.user_id, COUNT(*) AS total_comments
    FROM photos p
    JOIN comments c ON p.id = c.photo_id
    GROUP BY p.user_id
) c ON u.id = c.user_id
LEFT JOIN (
    SELECT followee_id AS user_id, COUNT(*) AS total_followers
    FROM follows
    GROUP BY followee_id
) f ON u.id = f.user_id
ORDER BY avg_likes_per_post DESC, avg_comments_per_post DESC
LIMIT 10;

-- 2.	For inactive users, what strategies would you recommend to re-engage them and encourage them to start posting or engaging again?
SELECT *
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
WHERE p.id IS NULL
order by u.id

-- For Active number of users
-- with active_users as(
-- SELECT 
-- u.username,
-- u.created_at,
-- p.image_url,
-- p.user_id,
-- p.id,
-- p.created_dat,
-- row_number() over(partition by p.user_id order by u.username) as rnk
-- FROM users u
-- LEFT JOIN photos p ON u.id = p.user_id
-- WHERE p.id IS not NULL
-- order by u.id
-- )
-- select 
-- * 
-- from active_users
-- where rnk=1;

-- 3.	Which hashtags or content topics have the highest engagement rates? How can this information guide content strategy and ad campaigns?
WITH hashtag_engagement AS (
  SELECT 
    ht.tag_name,
    COUNT(DISTINCT l.photo_id) AS total_likes,        -- count actual likes
    COUNT(DISTINCT c.id) AS total_comments,     -- count actual comments
    COUNT(DISTINCT p.id) AS total_photos
  FROM tags ht
  join photos p on ht.id=p.user_id
  JOIN photo_tags pt ON ht.id = pt.tag_id
  LEFT JOIN likes l ON pt.photo_id = l.photo_id
  LEFT JOIN comments c ON pt.photo_id = c.photo_id
  GROUP BY ht.tag_name
)
SELECT 
  tag_name,
  total_likes,
  total_comments,
  total_photos,
  ROUND(total_likes * 1.0 / NULLIF(total_photos, 0), 2) AS avg_likes_per_post,
  ROUND(total_comments * 1.0 / NULLIF(total_photos, 0), 2) AS avg_comments_per_post
FROM hashtag_engagement
ORDER BY avg_likes_per_post DESC, avg_comments_per_post DESC;

-- 4.	Are there any patterns or trends in user engagement based on demographics (age, location, gender) or posting times? How can these insights inform targeted marketing campaigns?
SELECT 
  HOUR(u.created_at) AS post_hour,
  COUNT(DISTINCT l.photo_id) AS likes,
  COUNT(DISTINCT c.id) AS comments
FROM photos p
join users u on p.id=u.id
LEFT JOIN likes l ON p.id = l.photo_id
LEFT JOIN comments c ON p.id = c.photo_id
GROUP BY post_hour
ORDER BY post_hour;

-- 5.	Based on follower counts and engagement rates, which users would be ideal candidates for influencer marketing campaigns? How would you approach and collaborate with these influencers?
SELECT 
  username,
  follower_count,
  total_posts,
  total_likes_received,
  total_comments_received,
  engagement_rate_percent
FROM (
    SELECT 
      u.username,
	  COALESCE(follower_data.follower_count, 0) AS follower_count,
      COALESCE(p.total_posts, 0) AS total_posts,
      COALESCE(l.total_likes, 0) AS total_likes_received,
      COALESCE(c.total_comments, 0) AS total_comments_received,
      ROUND(
        (COALESCE(l.total_likes, 0) + COALESCE(c.total_comments, 0)) * 100.0 
        / NULLIF(COALESCE(follower_data.follower_count, 0) * COALESCE(p.total_posts, 0), 0), 
        2
    ) AS engagement_rate_percent
    FROM users u
    LEFT JOIN (
    SELECT followee_id AS user_id, COUNT(*) AS follower_count
    FROM follows
    GROUP BY followee_id
    ) AS follower_data ON u.id = follower_data.user_id
    LEFT JOIN (
        SELECT user_id, COUNT(*) AS total_posts
        FROM photos
        GROUP BY user_id
    ) p ON u.id = p.user_id
    LEFT JOIN (
        SELECT p.user_id, COUNT(*) AS total_likes
        FROM photos p
        JOIN likes l ON l.photo_id = p.id
        GROUP BY p.user_id
    ) l ON u.id = l.user_id
    LEFT JOIN (
        SELECT p.user_id, COUNT(*) AS total_comments
        FROM photos p
        JOIN comments c ON c.photo_id = p.id
        GROUP BY p.user_id
    ) c ON u.id = c.user_id
    WHERE COALESCE(p.total_posts, 0) > 0
) ranked
ORDER BY engagement_rate_percent DESC, follower_count DESC
LIMIT 10;

-- 6.	Based on user behavior and engagement data, how would you segment the user base for targeted marketing campaigns or personalized recommendations?
SELECT segment, COUNT(*) AS total_users
FROM (
  SELECT 
    u.id,
    CASE
      WHEN COALESCE(p.total_posts, 0) >= 10 AND COALESCE(e.total_engagement, 0) >= 100 THEN 'Highly Engaged'
      WHEN COALESCE(p.total_posts, 0) >= 15 THEN 'Creators'
      WHEN COALESCE(f.total_followers, 0) >= 100 THEN 'Influencers'
      WHEN COALESCE(p.total_posts, 0) = 0 AND COALESCE(e.total_engagement, 0) = 0 THEN 'Inactive Users'
      WHEN COALESCE(c.total_comments, 0) >= 20 THEN 'Commenters'
      ELSE 'Other'
    END AS segment
  FROM users u
  LEFT JOIN (
    SELECT user_id, COUNT(*) AS total_posts
    FROM photos
    GROUP BY user_id
  ) p ON u.id = p.user_id
  LEFT JOIN (
    SELECT p.user_id, COUNT(l.photo_id) + COUNT(c.id) AS total_engagement
    FROM photos p
    LEFT JOIN likes l ON p.id = l.photo_id
    LEFT JOIN comments c ON p.id = c.photo_id
    GROUP BY p.user_id
  ) e ON u.id = e.user_id
  LEFT JOIN (
    SELECT followee_id AS user_id, COUNT(*) AS total_followers
    FROM follows
    GROUP BY followee_id
  ) f ON u.id = f.user_id
  LEFT JOIN (
    SELECT user_id, COUNT(*) AS total_comments
    FROM comments
    GROUP BY user_id
  ) c ON u.id = c.user_id
) categorized
GROUP BY segment
ORDER BY segment;
























