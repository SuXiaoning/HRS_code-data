import pandas as pd
import numpy as np

# 定义输入和输出文件路径
input_file = r'C:\毕业设计-源汇匹配数据\源汇距离2051_2060.csv'
output_matrix_file = r'C:\毕业设计-源汇匹配数据\距离矩阵2051_2060.csv'

chunk_size = 1000  # 根据内存情况调整块大小
distance_dict = {}
zzz = 0

# 分块读取 CSV 文件
for chunk in pd.read_csv(input_file, chunksize=chunk_size):
    for _, row in chunk.iterrows():
        try:
            point1 = int(row.iloc[0])  # 将第一列转换为整数
            point2 = int(row.iloc[1])  # 将第二列转换为整数
            distance = float(row.iloc[2])  # 将第三列转换为浮点数，表示距离
            # 将距离存入字典，并确保对称
            distance_dict[(point1, point2)] = distance
            # distance_dict[(point2, point1)] = distance  # 如果需要对称矩阵可以取消注释
            zzz += 1
        except ValueError:
            # 跳过包含非数字数据的行
            continue

print(zzz)  # 输出处理的行数
xxx = len(distance_dict)
print(xxx)  # 输出字典中记录的距离对数量

# 提取唯一的点（索引）
points = set()
for (point1, point2) in distance_dict.keys():
    points.add(point1)
    points.add(point2)

yyy = len(points)
print(yyy)  # 输出总共的点数

# 创建距离矩阵
points = sorted(points)  # 对点进行排序，以确保顺序一致
distance_matrix = np.zeros((len(points), len(points)), dtype=float)

# 填充距离矩阵
for (p1, p2), distance in distance_dict.items():
    i = points.index(p1)
    j = points.index(p2)
    distance_matrix[i, j] = distance

# 保存为新的 CSV 文件
pd.DataFrame(distance_matrix, index=points, columns=points).to_csv(output_matrix_file)

print("距离矩阵已保存到", output_matrix_file)
