#���� ��ġ ����
setwd("C:/.1.EWHA WOMAS UNIVERSITY/4-3/ĸ����/riss_data") 

#��ġ�Ǿ��ִ� ��쿡�� �̺κ� ����
#install.packages("pacman")
pacman::p_load('tidymodels','tidytext','NLP4kec' ,'stringr','magrittr','tm', 'network','GGally', 'sna', 'RColorBrewer')

riss_geder_conflict_title <- read.csv('gender_conflict_title.csv')
RGCT_txt <- as.data.frame(riss_geder_conflict_title, stringsAsFactors = F)

# �ؽ�Ʈ�� �ߺ��� �� ����
RGCT_txt <- unique(RGCT_txt)

# �ؽ�Ʈ�� ������ ����. NLP4kec ���¼� �м��Ⱑ ���⸦ ����
RGCT_txt <- sapply(RGCT_txt,str_remove_all,'\\s+')
RGCT_txt <- as.data.frame(RGCT_txt,stringsAsFactors = FALSE)
colnames(RGCT_txt) <- c('content')

#�� �̸��� content�� id�� ����
generateIDs <- function(obj, index = 'id') {
    # ��ü�� ������ ���� ���� ���
    if (obj %>% class() == 'data.frame') {
        n <- nrow(x = obj)
    } else {
        n <- length(x = obj)
    }
    # id ���� 
    id <- str_c(
        index, 
        str_pad(
            string = 1:n, 
            width = ceiling(x = log10(x = n)), 
            side = 'left', 
            pad = '0') )
    # ��� ��ȯ
    return(id)
}  
RGCT_txt$id <- generateIDs(obj = RGCT_txt, index = 'doc')
#�� �̸��� content�� id�� ���� 
names(RGCT_txt) <- c("content","id")

#���¼� �м�(NLP4kec ��Ű��)
Parsed_RGCT <- r_parser_r(RGCT_txt$content,language = "ko")
Parsed_RGCT <- Parsed_RGCT[Parsed_RGCT != ""]

#corpus ����
corp <- VCorpus(VectorSource(Parsed_RGCT))
#Ư������ ����
corp <-  tm_map(corp, removePunctuation)

#dtmTfIdf
dtmTfIdf <- DocumentTermMatrix( x = corp, control = list( removeNumbers = TRUE, wordLengths = c(2, Inf), weighting = function(x) weightTfIdf(x, normalize = TRUE) ))  

# dtmTfIdf ���� ���
dtmTfIdf <- removeSparseTerms(x =  dtmTfIdf, sparse = as.numeric(x = 0.99))

#corTerms
dtmTfIdf %>% as.matrix() %>% cor() -> corTerms

# Ű���� ������ Ȯ���մϴ�.
checkCorTerms <- function(x,n = 10, keyword) {
    
    # Ű���� ������ Ȯ���մϴ�.
    x %>%
        colnames() %>%
        str_subset(pattern = keyword) %>%
        print()
    
    # ���� Ű���尡 �ִ� �÷��� ��ü �ܾ �Ѳ����� ����մϴ�.
    corRef <- data.frame()
    
    # ������ ���� ������ �����մϴ�.
    corRef <- x[ , keyword] %>%
        sort(decreasing = TRUE) %>%
        data.frame() %>%
        set_colnames(c('corr'))
    
    # �̸����� �մϴ�.
    head(x = corRef, n = n + 1)
}

checkCorTerms(corTerms, 10 ,'����')

#corTerms to network obj
netTerms <- network(x = corTerms, directed = FALSE)

#������ ũ�� ����
corTerms[corTerms <= 0.1] <- 0
netTerms <- network(x = corTerms, directed = FALSE)
plot(netTerms, vertex.cex = 1)

#�Ű��߽ɼ� ���
btnTerms <- betweenness(netTerms) 
btnTerms[1:10]

#�Ű��߽ɼ� ǥ��
netTerms %v% 'mode' <-
    ifelse(
        test = btnTerms >= quantile(x = btnTerms, probs = 0.90, na.rm = TRUE), 
        yes = 'Top', 
        no = 'Rest')
nodeColors <- c('Top' = 'gold', 'Rest' = 'lightgrey')
set.edge.value(netTerms, attrname = 'edgeSize', value = corTerms * 3)
ggnet2(
    net = netTerms,
    mode = 'fruchtermanreingold',
    layout.par = list(cell.jitter = 0.001),
    size.min = 15,
    label = TRUE,
    label.size = 3,
    node.color = 'mode',
    palette = nodeColors,
    node.size = sna::degree(dat = netTerms),
    edge.size = 'edgeSize',
    family = 'mono')+
    labs(title = "�Ű��߽ɼ� �ݿ��� �ܾ�-��Ʈ��ũ��")
)

